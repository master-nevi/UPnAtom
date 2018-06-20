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

/// TODO: For now rooting to NSObject to expose to Objective-C, see Github issue #16
open class UPnPRegistry: NSObject {
    fileprivate enum UPnPObjectNotificationType {
        case device
        case service
        
        func notificationComponents() -> (objectAddedNotificationName: String, objectRemoveNotificationName: String, objectKey: String) {
            switch self {
            case .device:
                return ("UPnPDeviceAddedNotification", "UPnPDeviceRemovedNotification", "UPnPDeviceKey")
            case .service:
                return ("UPnPServiceAddedNotification", "UPnPServiceRemovedNotification", "UPnPServiceKey")
            }
        }
    }
    
    // private
    fileprivate let _concurrentUPnPObjectQueue = DispatchQueue(label: "com.upnatom.upnp-registry.upnp-object-queue", attributes: DispatchQueue.Attributes.concurrent)
    /// Must be accessed within dispatch_sync() or dispatch_async() and updated within dispatch_barrier_async() to the concurrent queue
    lazy fileprivate var _upnpObjects = [UniqueServiceName: AbstractUPnP]()
    lazy fileprivate var _upnpObjectsMainThreadCopy = [UniqueServiceName: AbstractUPnP]() // main thread safe copy
    /// Must be accessed within dispatch_sync() or dispatch_async() and updated within dispatch_barrier_async() to the concurrent queue
    lazy fileprivate var _ssdpDiscoveryCache = [SSDPDiscovery]()
    fileprivate let _upnpObjectDescriptionSessionManager = AFHTTPSessionManager()
    fileprivate var _upnpClasses = [String: AbstractUPnP.Type]()
    fileprivate let _ssdpDiscoveryAdapter: SSDPDiscoveryAdapter
    
    init(ssdpDiscoveryAdapter: SSDPDiscoveryAdapter) {
        _upnpObjectDescriptionSessionManager.requestSerializer = AFHTTPRequestSerializer()
        _upnpObjectDescriptionSessionManager.responseSerializer = AFHTTPResponseSerializer()
        
        _ssdpDiscoveryAdapter = ssdpDiscoveryAdapter
        super.init()
        ssdpDiscoveryAdapter.delegate = self
    }
    
    /// Safe to call from any thread
    open func upnpDevices(completionQueue: OperationQueue, completion: @escaping (_ upnpDevices: [AbstractUPnPDevice]) -> Void) {
        upnpObjects { (upnpObjects: [UniqueServiceName: AbstractUPnP]) -> Void in
            let upnpDevices = Array(upnpObjects.values).filter({$0 is AbstractUPnPDevice})
            
            completionQueue.addOperation({ () -> Void in
                completion(upnpDevices as! [AbstractUPnPDevice])
            })
        }
    }
    
    /// Safe to call from any thread
    open func upnpServices(completionQueue: OperationQueue, completion: @escaping (_ upnpServices: [AbstractUPnPService]) -> Void) {
        upnpObjects { (upnpObjects: [UniqueServiceName: AbstractUPnP]) -> Void in
            let upnpServices = Array(upnpObjects.values).filter({$0 is AbstractUPnPService})
            
            completionQueue.addOperation({ () -> Void in
                completion(upnpServices as! [AbstractUPnPService])
            })
        }
    }
    
    open func register(upnpClass: AbstractUPnP.Type, forURN urn: String) {
        _upnpClasses[urn] = upnpClass
    }
    
    open func createUPnPObject(upnpArchivable: UPnPArchivable, callbackQueue: OperationQueue, success: @escaping ((_ upnpObject: AbstractUPnP) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        let failureCase = { (error: NSError) -> Void in
            LogError("Unable to fetch UPnP object description for archivable: \(upnpArchivable.usn) at \(upnpArchivable.descriptionURL): \(error)")
            callbackQueue.addOperation({ () -> Void in
                failure(error)
            })
        }
        _upnpObjectDescriptionSessionManager.get(upnpArchivable.descriptionURL.absoluteString, parameters: nil, success: { (task, responseObject) -> Void in
            DispatchQueue.global(qos: .default).async(execute: { () -> Void in
                guard let xmlData = responseObject as? NSData,
                    let usn = UniqueServiceName(rawValue: upnpArchivable.usn),
                    let upnpObject = self.createUPnPObject(usn: usn, descriptionURL: upnpArchivable.descriptionURL, descriptionXML: xmlData as Data) else {
                        failureCase(createError("Unable to create UPnP object"))
                        return
                }
                
                callbackQueue.addOperation({ () -> Void in
                    success(upnpObject)
                })
            })
            }, failure: { (task, error) -> Void in
                print("having error: \(error)")
                failureCase(error as NSError)
        })
    }
    
    /// Safe to call from any thread, closure called on background thread
    fileprivate func upnpObjects(_ closure: @escaping (_ upnpObjects: [UniqueServiceName: AbstractUPnP]) -> Void) {
        // only reading upnp objects, so distpach_async is appropriate to allow for concurrent reads
        _concurrentUPnPObjectQueue.async(execute: { () -> Void in
            let upnpObjects = self._upnpObjects
            
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
                closure(upnpObjects)
            })
        })
    }
    
    /// Should be called on the background thread as every instance it creates parses XML
    fileprivate func createUPnPObject(usn: UniqueServiceName, descriptionURL: URL, descriptionXML: Data) -> AbstractUPnP? {
        let upnpClass: AbstractUPnP.Type
        let urn = usn.urn! // checked for nil earlier
        
        if let registeredClass = _upnpClasses[urn] {
            upnpClass = registeredClass
        } else if urn.range(of: "urn:schemas-upnp-org:device") != nil {
            upnpClass = AbstractUPnPDevice.self
        } else if urn.range(of: "urn:schemas-upnp-org:service") != nil {
            upnpClass = AbstractUPnPService.self
        } else {
            upnpClass = AbstractUPnP.self
        }
        
        return upnpClass.init(usn: usn, descriptionURL: descriptionURL, descriptionXML: descriptionXML)
    }
}

/// Extension used for defining notification constants. Functions are used since class constants are not supported in swift yet
public extension UPnPRegistry {
    class func UPnPDeviceAddedNotification() -> String {
        return UPnPObjectNotificationType.device.notificationComponents().objectAddedNotificationName
    }
    
    class func UPnPDeviceRemovedNotification() -> String {
        return UPnPObjectNotificationType.device.notificationComponents().objectRemoveNotificationName
    }
    
    class func UPnPDeviceKey() -> String {
        return UPnPObjectNotificationType.device.notificationComponents().objectKey
    }
    
    class func UPnPServiceAddedNotification() -> String {
        return UPnPObjectNotificationType.service.notificationComponents().objectAddedNotificationName
    }
    
    class func UPnPServiceRemovedNotification() -> String {
        return UPnPObjectNotificationType.service.notificationComponents().objectRemoveNotificationName
    }
    
    class func UPnPServiceKey() -> String {
        return UPnPObjectNotificationType.service.notificationComponents().objectKey
    }
    
    class func UPnPDiscoveryErrorNotification() -> String {
        return "UPnPDiscoveryErrorNotification"
    }
    
    class func UPnPDiscoveryErrorKey() -> String {
        return "UPnPDiscoveryErrorKey"
    }
}

extension UPnPRegistry: SSDPDiscoveryAdapterDelegate {
    func ssdpDiscoveryAdapter(_ adapter: SSDPDiscoveryAdapter, didUpdateSSDPDiscoveries ssdpDiscoveries: [SSDPDiscovery]) {
        _concurrentUPnPObjectQueue.async(flags: .barrier, execute: { () -> Void in
            self._ssdpDiscoveryCache = ssdpDiscoveries
            var upnpObjectsToKeep = [AbstractUPnP]()
            for ssdpDiscovery in ssdpDiscoveries {
                // only concerned with objects with a device or service type urn
                if ssdpDiscovery.usn.urn != nil {
                    switch ssdpDiscovery.type {
                    case .device, .service:
                        if let foundObject = self._upnpObjects[ssdpDiscovery.usn] {
                            upnpObjectsToKeep.append(foundObject)
                        } else {
                            self.getUPnPDescription(forSSDPDiscovery: ssdpDiscovery)
                        }
                    default:
                        LogVerbose("Discovery type will not be handled")
                    }
                }
            }
            
            self.process(upnpObjectsToKeep: upnpObjectsToKeep, upnpObjects: &self._upnpObjects)
        })
    }
    
    func ssdpDiscoveryAdapter(_ adapter: SSDPDiscoveryAdapter, didFailWithError error: NSError) {
        LogError("SSDP discovery did fail with error: \(error)")
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: UPnPRegistry.UPnPDiscoveryErrorNotification()), object: self, userInfo: [UPnPRegistry.UPnPDiscoveryErrorKey(): error])
        })
    }
    
    fileprivate func getUPnPDescription(forSSDPDiscovery ssdpDiscovery: SSDPDiscovery) {
        self._upnpObjectDescriptionSessionManager.get(ssdpDiscovery.descriptionURL.absoluteString, parameters: nil, success: { (task, responseObject) -> Void in
            (self._concurrentUPnPObjectQueue).async(flags: .barrier, execute: { () -> Void in
                if let xmlData = responseObject as? NSData {
                    // if ssdp object is not in cache then discard
                    guard self._ssdpDiscoveryCache.index(of: ssdpDiscovery) != nil else {
                        return
                    }
                    
                    self.addUPnPObject(forSSDPDiscovery: ssdpDiscovery, descriptionXML: xmlData as Data, upnpObjects: &self._upnpObjects)
                }
            })
            }, failure: { (task, error) -> Void in
                LogError("Unable to fetch UPnP object description for SSDP object: \(ssdpDiscovery.usn.description) at \(ssdpDiscovery.descriptionURL): \(error)")
        })
    }
    
    /// Must be called within dispatch_barrier_async() to the UPnP object queue since the upnpObjects dictionary is being updated
    fileprivate func addUPnPObject(forSSDPDiscovery ssdpDiscovery: SSDPDiscovery, descriptionXML: Data, upnpObjects: inout [UniqueServiceName: AbstractUPnP]) {
        let usn = ssdpDiscovery.usn
        
        // ignore if already in db
        guard upnpObjects[usn] == nil else {
            return
        }

        if let newObject = createUPnPObject(usn: usn, descriptionURL: ssdpDiscovery.descriptionURL as URL, descriptionXML: descriptionXML) {
            guard newObject is AbstractUPnPDevice || newObject is AbstractUPnPService else {
                return
            }
            
            if newObject is AbstractUPnPDevice {
                (newObject as! AbstractUPnPDevice).serviceSource = self
            } else {
                (newObject as! AbstractUPnPService).deviceSource = self
            }
            
            upnpObjects[usn] = newObject
            
            let upnpObjectsCopy = upnpObjects // create a copy for safe use on the main thread
            let notificationType: UPnPObjectNotificationType = newObject is AbstractUPnPDevice ? .device : .service
            let notificationComponents = notificationType.notificationComponents()
            DispatchQueue.main.async(execute: { () -> Void in
                self._upnpObjectsMainThreadCopy = upnpObjectsCopy
                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationComponents.objectAddedNotificationName), object: self, userInfo: [notificationComponents.objectKey: newObject])
            })
        }
    }
    
    /// Must be called within dispatch_barrier_async() to the UPnP object queue since the upnpObjects dictionary is being updated
    fileprivate func process(upnpObjectsToKeep: [AbstractUPnP], upnpObjects: inout [UniqueServiceName: AbstractUPnP]) {
        let upnpObjectsSet = Set(Array(upnpObjects.values))
        let upnpObjectsToRemove = upnpObjectsSet.subtracting(Set(upnpObjectsToKeep))
        
        for upnpObjectToRemove in upnpObjectsToRemove {
            upnpObjects.removeValue(forKey: upnpObjectToRemove.usn)
            
            let upnpObjectsCopy = upnpObjects // create a copy for safe use on the main thread
            let notificationType: UPnPObjectNotificationType = upnpObjectToRemove is AbstractUPnPDevice ? .device : .service
            let notificationComponents = notificationType.notificationComponents()
            DispatchQueue.main.async(execute: { () -> Void in
                self._upnpObjectsMainThreadCopy = upnpObjectsCopy
                NotificationCenter.default.post(name: Notification.Name(rawValue: notificationComponents.objectRemoveNotificationName), object: self, userInfo: [notificationComponents.objectKey: upnpObjectToRemove])
            })
        }
    }
}

extension UPnPRegistry: UPnPServiceSource {
    public func service(forUSN usn: UniqueServiceName) -> AbstractUPnPService? {
        return _upnpObjectsMainThreadCopy[usn] as? AbstractUPnPService
    }
}

extension UPnPRegistry: UPnPDeviceSource {
    public func device(forUSN usn: UniqueServiceName) -> AbstractUPnPDevice? {
        return _upnpObjectsMainThreadCopy[usn] as? AbstractUPnPDevice
    }
}
