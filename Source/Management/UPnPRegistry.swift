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
    
    // private
    private let _concurrentUPnPObjectQueue = dispatch_queue_create("com.upnatom.upnp-registry.upnp-object-queue", DISPATCH_QUEUE_CONCURRENT)
    /// Must be accessed within dispatch_sync() or dispatch_async() and updated within dispatch_barrier_async() to the concurrent queue
    lazy private var _upnpObjects = [UniqueServiceName: AbstractUPnP]()
    lazy private var _upnpObjectsMainThreadCopy = [UniqueServiceName: AbstractUPnP]() // main thread safe copy
    /// Must be accessed within dispatch_sync() or dispatch_async() and updated within dispatch_barrier_async() to the concurrent queue
    lazy private var _ssdpDiscoveryCache = [SSDPDiscovery]()
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
    
    /// Safe to call from any thread
    public func upnpDevices(#completionQueue: NSOperationQueue, completion: (upnpDevices: [AbstractUPnPDevice]) -> Void) {
        upnpObjects { (upnpObjects: [UniqueServiceName: AbstractUPnP]) -> Void in
            let upnpDevices = upnpObjects.values.array.filter({$0 is AbstractUPnPDevice})
            
            completionQueue.addOperationWithBlock({ () -> Void in
                completion(upnpDevices: upnpDevices as [AbstractUPnPDevice])
            })
        }
    }
    
    /// Safe to call from any thread
    public func upnpServices(#completionQueue: NSOperationQueue, completion: (upnpServices: [AbstractUPnPService]) -> Void) {
        upnpObjects { (upnpObjects: [UniqueServiceName: AbstractUPnP]) -> Void in
            let upnpServices = upnpObjects.values.array.filter({$0 is AbstractUPnPService})
            
            completionQueue.addOperationWithBlock({ () -> Void in
                completion(upnpServices: upnpServices as [AbstractUPnPService])
            })
        }
    }
    
    public func register(#upnpClass: AbstractUPnP.Type, forURN urn: String) {
        _upnpClasses[urn] = upnpClass
    }
    
    public func createUPnPObject(#upnpArchivable: UPnPArchivable, callbackQueue: NSOperationQueue, success: ((upnpObject: AbstractUPnP) -> Void), failure: ((error: NSError) -> Void)) {
        let failureCase = { (error: NSError) -> Void in
            LogError("Unable to fetch UPnP object description for archivable: \(upnpArchivable.usn) at \(upnpArchivable.descriptionURL): \(error)")
            callbackQueue.addOperationWithBlock({ () -> Void in
                failure(error: error)
            })
        }
        _upnpObjectDescriptionSessionManager.GET(upnpArchivable.descriptionURL.absoluteString, parameters: nil, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject?) -> Void in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                if let xmlData = responseObject as? NSData {
                    if let usn = UniqueServiceName(rawValue: upnpArchivable.usn) {
                        if let upnpObject = self.createUPnPObject(usn: usn, descriptionURL: upnpArchivable.descriptionURL, descriptionXML: xmlData) {
                            callbackQueue.addOperationWithBlock({ () -> Void in
                                success(upnpObject: upnpObject)
                            })
                            
                            return
                        }
                    }
                }
                
                failureCase(createError("Unable to create UPnP object"))
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError!) -> Void in
                failureCase(error)
        })
    }
    
    /// Safe to call from any thread, closure called on background thread
    private func upnpObjects(closure: (upnpObjects: [UniqueServiceName: AbstractUPnP]) -> Void) {
        // only reading upnp objects, so distpach_async is appropriate to allow for concurrent reads
        dispatch_async(_concurrentUPnPObjectQueue, { () -> Void in
            let upnpObjects = self._upnpObjects
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                closure(upnpObjects: upnpObjects)
            })
        })
    }
    
    /// Should be called on the background thread as every instance it creates parses XML
    private func createUPnPObject(#usn: UniqueServiceName, descriptionURL: NSURL, descriptionXML: NSData) -> AbstractUPnP? {
        var upnpClass: AbstractUPnP.Type!
        let urn = usn.urn! // checked for nil earlier
        
        if let registeredClass = _upnpClasses[urn] {
            upnpClass = registeredClass
        }
        else if urn.rangeOfString("urn:schemas-upnp-org:device") != nil {
            upnpClass = AbstractUPnPDevice.self
        }
        else if urn.rangeOfString("urn:schemas-upnp-org:service") != nil {
            upnpClass = AbstractUPnPService.self
        }
        else {
            upnpClass = AbstractUPnP.self
        }
        
        return upnpClass(usn: usn, descriptionURL: descriptionURL, descriptionXML: descriptionXML)
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

extension UPnPRegistry: SSDPDiscoveryAdapterDelegate {
    func ssdpDiscoveryAdapter(adapter: SSDPDiscoveryAdapter, didUpdateSSDPDiscoveries ssdpDiscoveries: [SSDPDiscovery]) {
        dispatch_barrier_async(_concurrentUPnPObjectQueue, { () -> Void in
            self._ssdpDiscoveryCache = ssdpDiscoveries
            var upnpObjectsToKeep = [AbstractUPnP]()
            for ssdpDiscovery in ssdpDiscoveries {
                // only concerned with objects with a device or service type urn
                if ssdpDiscovery.usn.urn != nil && (ssdpDiscovery.notificationType == .Device || ssdpDiscovery.notificationType == .Service) {
                    if let foundObject = self._upnpObjects[ssdpDiscovery.usn] {
                        upnpObjectsToKeep.append(foundObject)
                    }
                    else {
                        self.getUPnPDescription(forSSDPDiscovery: ssdpDiscovery)
                    }
                }
            }
            
            self.process(upnpObjectsToKeep: upnpObjectsToKeep, upnpObjects: &self._upnpObjects)
        })
    }
    
    func ssdpDiscoveryAdapter(adapter: SSDPDiscoveryAdapter, didFailWithError error: NSError) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(UPnPRegistry.UPnPDiscoveryErrorNotification(), object: self, userInfo: [UPnPRegistry.UPnPDiscoveryErrorKey(): error])
        })
    }
    
    private func getUPnPDescription(forSSDPDiscovery ssdpDiscovery: SSDPDiscovery) {
        self._upnpObjectDescriptionSessionManager.GET(ssdpDiscovery.descriptionURL.absoluteString, parameters: nil, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject?) -> Void in
            dispatch_barrier_async(self._concurrentUPnPObjectQueue, { () -> Void in
                if let xmlData = responseObject as? NSData {
                    // if ssdp object is not in cache then discard
                    if find(self._ssdpDiscoveryCache, ssdpDiscovery) == nil {
                        return
                    }
                    
                    self.addUPnPObject(forSSDPDiscovery: ssdpDiscovery, descriptionXML: xmlData, upnpObjects: &self._upnpObjects)
                }
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError!) -> Void in
                LogError("Unable to fetch UPnP object description for SSDP object: \(ssdpDiscovery.usn.description) at \(ssdpDiscovery.descriptionURL): \(error)")
        })
    }
    
    /// Must be called within dispatch_barrier_async() to the UPnP object queue since the upnpObjects dictionary is being updated
    private func addUPnPObject(forSSDPDiscovery ssdpDiscovery: SSDPDiscovery, descriptionXML: NSData, inout upnpObjects: [UniqueServiceName: AbstractUPnP]) {
        let usn = ssdpDiscovery.usn
        
        // ignore if already in db
        if let foundObject = upnpObjects[usn] {
            return
        }
        else {
            if let newObject = createUPnPObject(usn: usn, descriptionURL: ssdpDiscovery.descriptionURL, descriptionXML: descriptionXML) {
                if !(newObject is AbstractUPnPDevice) && !(newObject is AbstractUPnPService) {
                    return
                }
                
                upnpObjects[usn] = newObject
                
                let upnpObjectsCopy = upnpObjects // create a copy for safe use on the main thread
                let notificationType: UPnPObjectNotificationType = newObject is AbstractUPnPDevice ? .Device : .Service
                let notificationComponents = notificationType.notificationComponents()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self._upnpObjectsMainThreadCopy = upnpObjectsCopy
                    NSNotificationCenter.defaultCenter().postNotificationName(notificationComponents.objectAddedNotificationName, object: self, userInfo: [notificationComponents.objectKey: newObject])
                })
            }
        }
    }
    
    /// Must be called within dispatch_barrier_async() to the UPnP object queue since the upnpObjects dictionary is being updated
    private func process(#upnpObjectsToKeep: [AbstractUPnP], inout upnpObjects: [UniqueServiceName: AbstractUPnP]) {
        let upnpObjectsSet = NSMutableSet(array: Array(upnpObjects.values))
        upnpObjectsSet.minusSet(NSSet(array: upnpObjectsToKeep))
        let upnpObjectsToRemove = upnpObjectsSet.allObjects as [AbstractUPnP] // casting from [AnyObject]
        
        for upnpObjectToRemove in upnpObjectsToRemove {
            upnpObjects.removeValueForKey(upnpObjectToRemove.usn)
            
            let upnpObjectsCopy = upnpObjects // create a copy for safe use on the main thread
            let notificationType: UPnPObjectNotificationType = upnpObjectToRemove is AbstractUPnPDevice ? .Device : .Service
            let notificationComponents = notificationType.notificationComponents()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self._upnpObjectsMainThreadCopy = upnpObjectsCopy
                NSNotificationCenter.defaultCenter().postNotificationName(notificationComponents.objectRemoveNotificationName, object: self, userInfo: [notificationComponents.objectKey: upnpObjectToRemove])
            })
        }
    }
}

extension UPnPRegistry: UPnPServiceSource {
    public func serviceFor(#usn: UniqueServiceName) -> AbstractUPnPService? {
        return _upnpObjectsMainThreadCopy[usn] as? AbstractUPnPService
    }
}
