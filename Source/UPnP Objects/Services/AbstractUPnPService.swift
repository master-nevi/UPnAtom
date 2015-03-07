//
//  AbstractUPnPService.swift
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

public class AbstractUPnPService: AbstractUPnP {
    // public
    public var serviceType: String {
        return urn
    }
    public let serviceID: String!
    public var descriptionURL: NSURL {
        return NSURL(string: _relativeDescriptionURL.absoluteString!, relativeToURL: baseURL)!
    }
    public var controlURL: NSURL {
        return NSURL(string: _relativeControlURL.absoluteString!, relativeToURL: baseURL)!
    }
    public var eventURL: NSURL {
        return NSURL(string: _relativeEventURL.absoluteString!, relativeToURL: baseURL)!
    }
    override public var baseURL: NSURL! {
        if let baseURL = _baseURLFromXML {
            return baseURL
        }
        return super.baseURL
    }
    
    // protected = 🔰
    let sessionManager🔰: SOAPSessionManager!
    
    // private
    private let _baseURLFromXML: NSURL?
    private let _relativeDescriptionURL: NSURL!
    private let _relativeControlURL: NSURL!
    private let _relativeEventURL: NSURL!
    
    // MARK: UPnP Event handling related
    lazy private var _eventObservers = [EventObserver]() // Must be accessed within dispatch_sync() and updated within dispatch_barrier_async()
    private var _concurrentEventObserverQueue: dispatch_queue_t!
    private weak var _eventSubscription: AnyObject?
    
    override init?(ssdpObject: SSDPDBDevice_ObjC, upnpDescriptionXML: NSData) {
        super.init(ssdpObject: ssdpObject, upnpDescriptionXML: upnpDescriptionXML)
        
        sessionManager🔰 = SOAPSessionManager(baseURL: baseURL, sessionConfiguration: nil)
        
        _concurrentEventObserverQueue = dispatch_queue_create("com.upnatom.abstract-upnp-service.event-observer-queue.\(usn.rawValue)", DISPATCH_QUEUE_CONCURRENT)
        let serviceParser = UPnPServiceParser(upnpService: self, upnpDescriptionXML: upnpDescriptionXML)
        let parsedService = serviceParser.parse().value
        
        if let baseURL = parsedService?.baseURL {
            _baseURLFromXML = baseURL
        }
        
        if let serviceID = parsedService?.serviceID {
            self.serviceID = serviceID
        }
        else { return nil }
        
        if let relativeDescriptionURL = parsedService?.relativeDescriptionURL {
            self._relativeDescriptionURL = relativeDescriptionURL
        }
        else { return nil }
        
        if let relativeControlURL = parsedService?.relativeControlURL {
            self._relativeControlURL = relativeControlURL
        }
        else { return nil }
        
        if let relativeEventURL = parsedService?.relativeEventURL {
            self._relativeEventURL = relativeEventURL
        }
        else { return nil }
    }
    
    deinit {
        // deinit may be called during init if init returns nil, queue var may not be set
        if _concurrentEventObserverQueue == nil {
            return
        }
        
        var eventObservers: [EventObserver]!
        /// TODO: is dispatch_sync necessary for accessing if self is being dealloced?
        dispatch_sync(_concurrentEventObserverQueue, { () -> Void in
            eventObservers = self._eventObservers
        })
        
        for eventObserver in eventObservers {
            NSNotificationCenter.defaultCenter().removeObserver(eventObserver.notificationCenterObserver)
        }
    }
}

// MARK: UPnP Event handling

extension AbstractUPnPService: UPnPEventSubscriber {
    private class EventObserver {
        let notificationCenterObserver: AnyObject
        init(notificationCenterObserver: AnyObject) {
            self.notificationCenterObserver = notificationCenterObserver
        }
    }
    
    private func UPnPEventReceivedNotification() -> String {
        return "UPnPEventReceivedNotification.\(usn.rawValue)"
    }
    
    private class func UPnPEventKey() -> String {
        return "UPnPEventKey"
    }
    
    /// Use callBackBlock for event notifications. While the notifications are backed by NSNotifications for broadcasting, they should only be used internally in order to keep track of how many subscribers there are.
    public func addEventObserver(queue: NSOperationQueue?, callBackBlock: (event: UPnPEvent) -> Void) -> AnyObject {
        let observer = EventObserver(notificationCenterObserver: NSNotificationCenter.defaultCenter().addObserverForName(UPnPEventReceivedNotification(), object: nil, queue: queue) { [unowned self] (notification: NSNotification!) -> Void in
            if let event = notification.userInfo?[AbstractUPnPService.UPnPEventKey()] as? UPnPEvent {
                callBackBlock(event: event)
            }
        })
        
        dispatch_barrier_async(_concurrentEventObserverQueue, { () -> Void in
            self._eventObservers.append(observer)
            
            if self._eventObservers.count >= 1 {
                // subscribe
                UPnPManager_Swift.sharedInstance.eventSubscriptionManager.subscribe(self, eventURL: self.eventURL, completion: { (subscription: Result<AnyObject>) -> Void in
                    switch subscription {
                    case .Success(let value):
                        self._eventSubscription = value()
                    case .Failure(let error):
                        let errorDescription = error.localizedDescription("Unknown subscribe error")
                        DDLogError("Unable to subscribe to UPnP events from \(self.eventURL): \(errorDescription)")
                    }
                })
            }
        })
        
        return observer
    }
    
    func removeEventObserver(observer: AnyObject) {
        dispatch_barrier_async(_concurrentEventObserverQueue, { () -> Void in
            if let observer = observer as? EventObserver {
                removeObject(&self._eventObservers, observer)
                NSNotificationCenter.defaultCenter().removeObserver(observer.notificationCenterObserver)
            }
            
            if self._eventObservers.count == 0 {
                // unsubscribe
                UPnPManager_Swift.sharedInstance.eventSubscriptionManager.unsubscribe(self, completion: { (result: EmptyResult) -> Void in
                    switch result {
                    case .Success:
                        self._eventSubscription = nil
                    case .Failure(let error):
                        let errorDescription = error.localizedDescription("Unknown unsubscribe error")
                        DDLogError("Unable to unsubscribe to UPnP events from \(self.eventURL): \(errorDescription)")
                        self._eventSubscription = nil
                    }
                })
            }
        })
    }
    
    func handleEvent(eventSubscriptionManager: UPnPEventSubscriptionManager, eventXML: NSData) {
        NSNotificationCenter.defaultCenter().postNotificationName(UPnPEventReceivedNotification(), object: nil, userInfo: [AbstractUPnPService.UPnPEventKey(): self.createEvent(eventXML)])
    }
    
    func subscriptionDidFail(eventSubscriptionManager: UPnPEventSubscriptionManager) {
        DDLogWarn("Event subscription did fail for service: \(self)")
    }
    
    /// overridable by service subclasses
    func createEvent(eventXML: NSData) -> UPnPEvent {
        return UPnPEvent(eventXML: eventXML, service: self)
    }
}

extension AbstractUPnPService.EventObserver: Equatable { }

private func ==(lhs: AbstractUPnPService.EventObserver, rhs: AbstractUPnPService.EventObserver) -> Bool {
    return lhs.notificationCenterObserver === rhs.notificationCenterObserver
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isAbstractUPnPService() -> Bool {
        return self is AbstractUPnPService
    }
}

extension AbstractUPnPService: ExtendedPrintable {
    override public var className: String { return "AbstractUPnPService" }
    override public var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        properties.add("serviceType", property: serviceType)
        properties.add("serviceID", property: serviceID)
        properties.add("descriptionURL", property: descriptionURL.absoluteString)
        properties.add("controlURL", property: controlURL.absoluteString)
        properties.add("eventURL", property: eventURL.absoluteString)
        return properties.description
    }
}
