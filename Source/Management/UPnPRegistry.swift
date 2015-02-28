//
//  UPnPRegistry.swift
//
//  Copyright (c) 2015 David Robles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import upnpx

@objc public class UPnPRegistry {
    // public
    public var rootDevices: [AbstractUPnPDevice] {
        var rootDevices: [AbstractUPnPDevice]!
        dispatch_sync(_concurrentUPnPObjectQueue, { () -> Void in
            rootDevices = self._rootDevices.values.array
        })
        return rootDevices
    }
    
    // internal
    let ssdpDB: SSDPDB_ObjC
    
    // private
    private let _concurrentUPnPObjectQueue = dispatch_queue_create("com.upnatom.upnp-registry.upnp-object-queue", DISPATCH_QUEUE_CONCURRENT)
    lazy private var _rootDevices = [UniqueServiceName: AbstractUPnPDevice]() // Must be accessed within dispatch_sync() and updated within dispatch_barrier_async()
    lazy private var _rootDeviceServices = [UniqueServiceName: AbstractUPnPService]() // Must be accessed within dispatch_sync() and updated within dispatch_barrier_async()
    
    init(ssdpDB: SSDPDB_ObjC) {
        self.ssdpDB = ssdpDB
        ssdpDB.addObserver(self)
    }
    
    func serviceFor(#usn: UniqueServiceName) -> AbstractUPnPService? {
        var service: AbstractUPnPService?
        dispatch_sync(_concurrentUPnPObjectQueue, { () -> Void in
            service = self._rootDeviceServices[usn]
        })
        
        return service
    }
    
    /// MARK: unused method consider deleting
    func ssdpServicesFor(uuid: String) -> [SSDPDBDevice_ObjC] {
        ssdpDB.lock()
        
        var services = [SSDPDBDevice_ObjC]()
        
        for ssdpDevice in ssdpDB.SSDPObjCDevices {
            if let ssdpDevice = ssdpDevice as? SSDPDBDevice_ObjC {
                if ssdpDevice.isservice && ssdpDevice.uuid == uuid {
                    services.append(ssdpDevice)
                }
            }
        }
        
        ssdpDB.unlock()
        
        return services
    }
    
    /// MARK: unused method consider deleting
    private func addRootDevice(device: AbstractUPnPDevice) {
        dispatch_barrier_async(_concurrentUPnPObjectQueue, { () -> Void in
            self._rootDevices[device.usn] = device
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(UPnPRegistry.UPnPDeviceAddedNotification(), object: self, userInfo: [UPnPRegistry.UPnPDeviceKey(): device])
            })
        })
    }
}

/// Extension used for defining notification constants. Functions are used since class constants are not supported in swift yet
public extension UPnPRegistry {
    class func UPnPDeviceAddedNotification() -> String {
        return "UPnPDeviceAddedNotification"
    }
    
    class func UPnPDeviceRemovedNotification() -> String {
        return "UPnPDeviceRemovedNotification"
    }
    
    class func UPnPDeviceKey() -> String {
        return "UPnPDeviceKey"
    }
    
    class func UPnPServiceAddedNotification() -> String {
        return "UPnPServiceAddedNotification"
    }
    
    class func UPnPServiceRemovedNotification() -> String {
        return "UPnPServiceRemovedNotification"
    }
    
    class func UPnPServiceKey() -> String {
        return "UPnPServiceKey"
    }
}

extension UPnPRegistry: SSDPDB_ObjC_Observer {
    /// Ideally this should be internal, however it needs to be called from the upnpx lib
    public func SSDPDBWillUpdate(sender: SSDPDB_ObjC!) {
        
    }
    
    /// Ideally this should be internal, however it needs to be called from the upnpx lib
    public func SSDPDBUpdated(sender: SSDPDB_ObjC!) {
        let ssdpObjects = sender.SSDPObjCDevices.copy() as [SSDPDBDevice_ObjC]
        dispatch_barrier_async(_concurrentUPnPObjectQueue, { () -> Void in
            let devices = self._rootDevices
            var devicesToAdd = [AbstractUPnPDevice]()
            var devicesToKeep = [AbstractUPnPDevice]()
            let services = self._rootDeviceServices
            var servicesToAdd = [AbstractUPnPService]()
            var servicesToKeep = [AbstractUPnPService] ()
            for ssdpObject in ssdpObjects {
                if ssdpObject.uuid != nil && ssdpObject.urn != nil {
                    if ssdpObject.isdevice {
                        if let foundDevice = devices[UniqueServiceName(uuid: ssdpObject.uuid, urn: ssdpObject.urn)] {
                            devicesToKeep.append(foundDevice)
                        }
                        else {
                            if let newDevice = UPnPFactory.createDeviceFrom(ssdpObject) {
                                devicesToAdd.append(newDevice)
                            }
                        }
                    }
                    else if ssdpObject.isservice {
                        if let foundService = services[UniqueServiceName(uuid: ssdpObject.uuid, urn: ssdpObject.urn)] {
                            servicesToKeep.append(foundService)
                        }
                        else {
                            if let newService = UPnPFactory.createServiceFrom(ssdpObject) {
                                servicesToAdd.append(newService)
                            }
                        }
                    }
                }
            }
            
            self.process(devicesToAdd: devicesToAdd, devicesToKeep: devicesToKeep)
            self.process(servicesToAdd: servicesToAdd, servicesToKeep: servicesToKeep)
        })
    }
    
    /// MARK: Must be called within dispatch_barrier_async()
    private func process(#devicesToAdd: [AbstractUPnPDevice], devicesToKeep: [AbstractUPnPDevice]) {
        let devices = self._rootDevices
        let devicesSet = NSMutableSet(array: Array(devices.values))
        devicesSet.minusSet(NSSet(array: devicesToKeep))
        let devicesToRemove = devicesSet.allObjects as [AbstractUPnPDevice] // casting from [AnyObject]
        
        for deviceToRemove in devicesToRemove {
            self._rootDevices.removeValueForKey(deviceToRemove.usn)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(UPnPRegistry.UPnPDeviceRemovedNotification(), object: self, userInfo: [UPnPRegistry.UPnPDeviceKey(): deviceToRemove])
            })
        }
        
        for deviceToAdd in devicesToAdd {
            self._rootDevices[deviceToAdd.usn] = deviceToAdd
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(UPnPRegistry.UPnPDeviceAddedNotification(), object: self, userInfo: [UPnPRegistry.UPnPDeviceKey(): deviceToAdd])
            })
        }
    }
    
    /// MARK: Must be called within dispatch_barrier_async()
    private func process(#servicesToAdd: [AbstractUPnPService], servicesToKeep: [AbstractUPnPService]) {
        let services = self._rootDeviceServices
        let servicesSet = NSMutableSet(array: Array(services.values))
        servicesSet.minusSet(NSSet(array: servicesToKeep))
        let servicesToRemove = servicesSet.allObjects as [AbstractUPnPService] // casting from [AnyObject]
        
        for serviceToRemove in servicesToRemove {
            self._rootDeviceServices.removeValueForKey(serviceToRemove.usn)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(UPnPRegistry.UPnPServiceRemovedNotification(), object: self, userInfo: [UPnPRegistry.UPnPServiceKey(): serviceToRemove])
            })
        }
        
        for serviceToAdd in servicesToAdd {
            self._rootDeviceServices[serviceToAdd.usn] = serviceToAdd
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(UPnPRegistry.UPnPServiceAddedNotification(), object: self, userInfo: [UPnPRegistry.UPnPServiceKey(): serviceToAdd])
            })
        }
    }
}
