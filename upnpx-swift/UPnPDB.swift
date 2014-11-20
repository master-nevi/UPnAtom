//
//  UPnPDB.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/16/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class UPnPDB_Swift {
    // public
    let UPnPDeviceWasAddedNotification = "UPnPDeviceWasAddedNotification"
    let UPnPDeviceWasRemovedNotification = "UPnPDeviceWasRemovedNotification"
    let UPnPDeviceKey = "UPnPDeviceKey"
    var rootDevices: [BasicUPnPDevice_Swift] {
        var rootDevices: [BasicUPnPDevice_Swift]!
        dispatch_sync(_concurrentDeviceQueue, { () -> Void in
            rootDevices = Array(self._rootDevices.values)
        })
        return rootDevices
    }
    let ssdpDB: SSDPDB_ObjC
    
    // private
    private let _concurrentDeviceQueue = dispatch_queue_create("com.upnpx.swift.rootDeviceQueue", DISPATCH_QUEUE_CONCURRENT)
    lazy private var _rootDevices = [String: BasicUPnPDevice_Swift]()
    
    init(ssdpDB: SSDPDB_ObjC) {
        self.ssdpDB = ssdpDB
        ssdpDB.addSSDPDBObserver(self)
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
    
    private func addRootDevice(device: BasicUPnPDevice_Swift) {
        dispatch_barrier_async(_concurrentDeviceQueue, { () -> Void in
            self._rootDevices[device.usn] = device
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(self.UPnPDeviceWasAddedNotification, object: self, userInfo: [self.UPnPDeviceKey: device])
            })
        })
    }
}

extension UPnPDB_Swift: SSDPDB_ObjC_Observer {
    func SSDPDBWillUpdate(sender: SSDPDB_ObjC!) {
        
    }
    
    func SSDPDBUpdated(sender: SSDPDB_ObjC!) {
        let ssdpDevices = sender.SSDPObjCDevices
        dispatch_barrier_async(_concurrentDeviceQueue, { () -> Void in
            let rootDevices = self._rootDevices
            var devicesToAdd = [BasicUPnPDevice_Swift]()
            var devicesToKeep = [BasicUPnPDevice_Swift]()
            for ssdpDevice in ssdpDevices {
                if let ssdpDevice = ssdpDevice as? SSDPDBDevice_ObjC {
                    if ssdpDevice.isdevice {
                        if let foundRootDevice = rootDevices[ssdpDevice.usn] {
                            devicesToKeep.append(foundRootDevice)
                        }
                        else {
                            let ssdpDeviceToAdd = ssdpDevice
                            let newDevice = BasicUPnPDevice_Swift() //from ssdpDeviceToAdd
                            newDevice.loadDeviceDescriptionFromXML()
                            devicesToAdd.append(newDevice)
                        }
                    }
                }
            }
            
            let rootDevicesSet = NSMutableSet(array: Array(rootDevices.values))
            rootDevicesSet.minusSet(NSSet(array: devicesToKeep))
            let devicesToRemove = rootDevicesSet.allObjects
            
            for deviceToRemove in devicesToRemove {
                self._rootDevices.removeValueForKey(deviceToRemove.usn)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(self.UPnPDeviceWasRemovedNotification, object: self, userInfo: [self.UPnPDeviceKey: deviceToRemove])
                })
            }
            
            for deviceToAdd in devicesToAdd {
                self._rootDevices[deviceToAdd.usn] = deviceToAdd
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(self.UPnPDeviceWasAddedNotification, object: self, userInfo: [self.UPnPDeviceKey: deviceToAdd])
                })
            }
        })
    }
}
