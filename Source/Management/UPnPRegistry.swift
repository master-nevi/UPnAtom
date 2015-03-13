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
import AFNetworking

@objc public class UPnPRegistry {
    private enum UPnPObjectNotificationType {
        case Device
        case Service
        
        func notificationComponents() -> (objectAddedNotificationName: String, objectRemoveNotificationName: String, objectKey: String) {
            switch self {
            case Device:
                return ("UPnPDeviceAddedNotification", "UPnPDeviceRemovedNotification", "UPnPDeviceKey")
            case Service:
                return ("UPnPServiceAddedNotification", "UPnPServiceRemovedNotification", "UPnPServiceKey")
            }
        }
    }
    
    // public
    /// Calling this on the main thread is not recommended as it will block until completed, blocking the main thread is a no-no
    public var rootDevices: [AbstractUPnPDevice] {
        var rootDevices: [AbstractUPnPDevice]!
        dispatch_sync(_concurrentUPnPObjectQueue, { () -> Void in
            rootDevices = self._rootDevices.values.array
        })
        return rootDevices
    }
    
    // private
    private let _concurrentUPnPObjectQueue = dispatch_queue_create("com.upnatom.upnp-registry.upnp-object-queue", DISPATCH_QUEUE_CONCURRENT)
    lazy private var _rootDevices = [UniqueServiceName: AbstractUPnPDevice]() // Must be accessed within dispatch_sync() and updated within dispatch_barrier_async()
    lazy private var _rootDeviceServices = [UniqueServiceName: AbstractUPnPService]() // Must be accessed within dispatch_sync() and updated within dispatch_barrier_async()
    lazy private var _ssdpObjectCache = [SSDPObject]() // Must be accessed within dispatch_sync() and updated within dispatch_barrier_async()
    private let _upnpObjectDescriptionSessionManager = AFHTTPSessionManager()
    private var _upnpClasses = [String: AbstractUPnP.Type]()
    private let _ssdpDiscoveryAdapter: SSDPDiscoveryAdapter
    
    init(ssdpDiscoveryAdapter: SSDPDiscoveryAdapter) {
        _upnpObjectDescriptionSessionManager.requestSerializer = AFHTTPRequestSerializer()
        _upnpObjectDescriptionSessionManager.responseSerializer = AFHTTPResponseSerializer()
        
        _ssdpDiscoveryAdapter = ssdpDiscoveryAdapter
        
        register(upnpClass: MediaRenderer1Device.self, forURN: "urn:schemas-upnp-org:device:MediaRenderer:1")
        register(upnpClass: MediaServer1Device.self, forURN: "urn:schemas-upnp-org:device:MediaServer:1")
        register(upnpClass: AVTransport1Service.self, forURN: "urn:schemas-upnp-org:service:AVTransport:1")
        register(upnpClass: ConnectionManager1Service.self, forURN: "urn:schemas-upnp-org:service:ConnectionManager:1")
        register(upnpClass: ContentDirectory1Service.self, forURN: "urn:schemas-upnp-org:service:ContentDirectory:1")
        register(upnpClass: RenderingControl1Service.self, forURN: "urn:schemas-upnp-org:service:RenderingControl:1")
        
        // prevent callbacks until all the default upnp classes have been registered
        ssdpDiscoveryAdapter.delegate = self
    }
    
    /// Safe to call from main thread
    public func rootDevices(closure: (rootDevices: [AbstractUPnPDevice]) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let rootDevices = self.rootDevices
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                closure(rootDevices: rootDevices)
            })
        })
    }
    
    public func register(#upnpClass: AbstractUPnP.Type, forURN urn: String) {
        _upnpClasses[urn] = upnpClass
    }
    
    func serviceFor(#usn: UniqueServiceName) -> AbstractUPnPService? {
        var service: AbstractUPnPService?
        dispatch_sync(_concurrentUPnPObjectQueue, { () -> Void in
            service = self._rootDeviceServices[usn]
        })
        
        return service
    }
    
    private func createUPnPObject(ssdpObject: SSDPObject, upnpDescriptionXML: NSData) -> AbstractUPnP? {
        var upnpClass: AbstractUPnP.Type!
        let uuid = ssdpObject.uuid
        let urn = ssdpObject.urn!
        let usn = UniqueServiceName(uuid: uuid, urn: urn, customRawValue: ssdpObject.usn)
        let xmlLocation = ssdpObject.xmlLocation
        
        if let registeredClass = _upnpClasses[urn] {
            LogVerbose("creating registered class for urn: \(urn)")
            upnpClass = registeredClass
        }
        else if urn.rangeOfString("urn:schemas-upnp-org:device") != nil {
            LogVerbose("creating AbstractUPnPDevice for urn: \(urn)")
            upnpClass = AbstractUPnPDevice.self
        }
        else if urn.rangeOfString("urn:schemas-upnp-org:service") != nil {
            LogVerbose("creating AbstractUPnPService for urn: \(urn)")
            upnpClass = AbstractUPnPService.self
        }
        else {
            LogVerbose("creating AbstractUPnP for urn: \(urn)")
            upnpClass = AbstractUPnP.self
        }
        
        return upnpClass(uuid: uuid, urn: urn, usn: usn, xmlLocation: xmlLocation, upnpDescriptionXML: upnpDescriptionXML)
    }
}

/// Extension used for defining notification constants. Functions are used since class constants are not supported in swift yet
public extension UPnPRegistry {
    class func UPnPDeviceAddedNotification() -> String {
        return UPnPObjectNotificationType.Device.notificationComponents().objectAddedNotificationName
    }
    
    class func UPnPDeviceRemovedNotification() -> String {
        return UPnPObjectNotificationType.Device.notificationComponents().objectRemoveNotificationName
    }
    
    class func UPnPDeviceKey() -> String {
        return UPnPObjectNotificationType.Device.notificationComponents().objectKey
    }
    
    class func UPnPServiceAddedNotification() -> String {
        return UPnPObjectNotificationType.Service.notificationComponents().objectAddedNotificationName
    }
    
    class func UPnPServiceRemovedNotification() -> String {
        return UPnPObjectNotificationType.Service.notificationComponents().objectRemoveNotificationName
    }
    
    class func UPnPServiceKey() -> String {
        return UPnPObjectNotificationType.Service.notificationComponents().objectKey
    }
    
    class func UPnPDiscoveryErrorNotification() -> String {
        return "UPnPDiscoveryErrorNotification"
    }
    
    class func UPnPDiscoveryErrorKey() -> String {
        return "UPnPDiscoveryErrorKey"
    }
}

extension UPnPRegistry: SSDPDiscoveryDelegate {
    func ssdpDiscoveryAdapter(adapter: SSDPDiscoveryAdapter, didUpdateSSDPObjects ssdpObjects: [SSDPObject]) {
        dispatch_barrier_async(_concurrentUPnPObjectQueue, { () -> Void in
            self._ssdpObjectCache = ssdpObjects
            var devicesToKeep = [AbstractUPnPDevice]()
            var servicesToKeep = [AbstractUPnPService]()
            for ssdpObject in ssdpObjects {
                // only concerned with objects with a device or service type urn
                if ssdpObject.urn != nil && (ssdpObject.notificationType == .Device || ssdpObject.notificationType == .Service) {
                    let usn = UniqueServiceName(uuid: ssdpObject.uuid, urn: ssdpObject.urn!)
                    if let foundDevice = self._rootDevices[usn] {
                        devicesToKeep.append(foundDevice)
                    }
                    else if let foundService = self._rootDeviceServices[usn] {
                        servicesToKeep.append(foundService)
                    }
                    else {
                        self.getUPnPDescription(forSSDPObject: ssdpObject)
                    }
                }
            }
            
            self.process(upnpObjectsToKeep: devicesToKeep, upnpObjects: &self._rootDevices, notificationType: .Device)
            self.process(upnpObjectsToKeep: servicesToKeep, upnpObjects: &self._rootDeviceServices, notificationType: .Service)
        })
    }
    
    func ssdpDiscoveryAdapter(adapter: SSDPDiscoveryAdapter, didFailWithError error: NSError) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(UPnPRegistry.UPnPDiscoveryErrorNotification(), object: self, userInfo: [UPnPRegistry.UPnPDiscoveryErrorKey(): error])
        })
    }
    
    private func getUPnPDescription(forSSDPObject ssdpObject: SSDPObject) {
        self._upnpObjectDescriptionSessionManager.GET(ssdpObject.xmlLocation.absoluteString, parameters: nil, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject?) -> Void in
            dispatch_barrier_async(self._concurrentUPnPObjectQueue, { () -> Void in
                if let xmlData = responseObject as? NSData {
                    // if ssdp object is not in cache then discard
                    if find(self._ssdpObjectCache, ssdpObject) == nil {
                        return
                    }
                    
                    if ssdpObject.notificationType == .Device {
                        self.addUPnPObject(forSSDPObject: ssdpObject, upnpDescriptionXML: xmlData, upnpObjects: &self._rootDevices, notificationType: .Device)
                    }
                    else if ssdpObject.notificationType == .Service {
                        self.addUPnPObject(forSSDPObject: ssdpObject, upnpDescriptionXML: xmlData, upnpObjects: &self._rootDeviceServices, notificationType: .Service)
                    }
                }
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError!) -> Void in
                // log
        })
    }
    
    /// Must be called within dispatch_barrier_async()
    private func addUPnPObject<T: AbstractUPnP>(forSSDPObject ssdpObject: SSDPObject, upnpDescriptionXML: NSData, inout upnpObjects: [UniqueServiceName: T], notificationType: UPnPObjectNotificationType) {
        // ignore if already in db
        let usn = UniqueServiceName(uuid: ssdpObject.uuid, urn: ssdpObject.urn!)
        if let foundObject = upnpObjects[usn] {
            return
        }
        else {
            if let newObject = createUPnPObject(ssdpObject, upnpDescriptionXML: upnpDescriptionXML) {
                if let newObject = newObject as? T {
                    upnpObjects[usn] = newObject
                    
                    let notificationComponents = notificationType.notificationComponents()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(notificationComponents.objectAddedNotificationName, object: self, userInfo: [notificationComponents.objectKey: newObject])
                    })
                }
            }
        }
    }
    
    /// Must be called within dispatch_barrier_async()
    private func process<T: AbstractUPnP>(#upnpObjectsToKeep: [T], inout upnpObjects: [UniqueServiceName: T], notificationType: UPnPObjectNotificationType) {
        let upnpObjectsSet = NSMutableSet(array: Array(upnpObjects.values))
        upnpObjectsSet.minusSet(NSSet(array: upnpObjectsToKeep))
        let upnpObjectsToRemove = upnpObjectsSet.allObjects as [T] // casting from [AnyObject]
        
        for upnpObjectToRemove in upnpObjectsToRemove {
            upnpObjects.removeValueForKey(upnpObjectToRemove.usn)
            
            let notificationComponents = notificationType.notificationComponents()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(notificationComponents.objectRemoveNotificationName, object: self, userInfo: [notificationComponents.objectKey: upnpObjectToRemove])
            })
        }
    }
}
