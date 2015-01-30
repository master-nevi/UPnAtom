//
//  UPnPRegistry.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/16/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

@objc class UPnPRegistry {
    // public
    var rootDevices: [AbstractUPnPDevice] {
        var rootDevices: [AbstractUPnPDevice]!
        dispatch_sync(_concurrentDeviceQueue, { () -> Void in
            rootDevices = Array(self._rootDevices.values)
        })
        return rootDevices
    }
    let ssdpDB: SSDPDB_ObjC
    
    // private
    private let _concurrentDeviceQueue = dispatch_queue_create("com.upnatom.upnp-registry.device-queue", DISPATCH_QUEUE_CONCURRENT)
    lazy private var _rootDevices = [UniqueServiceName: AbstractUPnPDevice]()
    lazy private var _rootDeviceServices = [UniqueServiceName: AbstractUPnPService]()
    
    init(ssdpDB: SSDPDB_ObjC) {
        self.ssdpDB = ssdpDB
        ssdpDB.addObserver(self)
    }
    
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
        dispatch_barrier_async(_concurrentDeviceQueue, { () -> Void in
            self._rootDevices[device.usn] = device
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(UPnPRegistry.UPnPDeviceAddedNotification(), object: self, userInfo: [UPnPRegistry.UPnPDeviceKey(): device])
            })
        })
    }
}

/// Extension used for defining notification constants. Functions are used since class constants are not supported in swift yet
extension UPnPRegistry {
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
    internal func SSDPDBWillUpdate(sender: SSDPDB_ObjC!) {
        
    }
    
    internal func SSDPDBUpdated(sender: SSDPDB_ObjC!) {
        let ssdpDevices = sender.SSDPObjCDevices.copy() as [SSDPDBDevice_ObjC]
        dispatch_barrier_async(_concurrentDeviceQueue, { () -> Void in
            let devices = self._rootDevices
            var devicesToAdd = [AbstractUPnPDevice]()
            var devicesToKeep = [AbstractUPnPDevice]()
            let services = self._rootDeviceServices
            var servicesToAdd = [AbstractUPnPService]()
            var servicesToKeep = [AbstractUPnPService] ()
            for ssdpDevice in ssdpDevices {
                if ssdpDevice.uuid != nil && ssdpDevice.urn != nil {
                    if ssdpDevice.isdevice {
                        if let foundDevice = devices[UniqueServiceName(uuid: ssdpDevice.uuid, urn: ssdpDevice.urn)] {
                            devicesToKeep.append(foundDevice)
                        }
                        else {
                            if let newDevice = UPnPFactory.createDeviceFrom(ssdpDevice) {
                                devicesToAdd.append(newDevice)
                            }
                        }
                    }
                    else if ssdpDevice.isservice {
                        if let foundService = services[UniqueServiceName(uuid: ssdpDevice.uuid, urn: ssdpDevice.urn)] {
                            servicesToKeep.append(foundService)
                        }
                        else {
                            if let newService = UPnPFactory.createServiceFrom(ssdpDevice) {
                                servicesToAdd.append(newService)
                            }
                        }
                    }
                }
            }
            
            self.process(devicesToAdd, devicesToKeep: devicesToKeep)
            self.process(servicesToAdd, servicesToKeep: servicesToKeep)
        })
    }
    
    private func process(devicesToAdd: [AbstractUPnPDevice], devicesToKeep: [AbstractUPnPDevice]) {
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
    
    private func process(servicesToAdd: [AbstractUPnPService], servicesToKeep: [AbstractUPnPService]) {
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
