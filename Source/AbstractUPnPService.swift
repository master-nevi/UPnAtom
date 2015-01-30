//
//  AbstractUPnPService.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class AbstractUPnPService: AbstractUPnP {
    // public
    var serviceType: String {
        return urn
    }
    let serviceID: String!
    var descriptionURL: NSURL {
        return NSURL(string: _relativeDescriptionURL.absoluteString!, relativeToURL: baseURL)!
    }
    var controlURL: NSURL {
        return NSURL(string: _relativeControlURL.absoluteString!, relativeToURL: baseURL)!
    }
    var eventURL: NSURL {
        return NSURL(string: _relativeEventURL.absoluteString!, relativeToURL: baseURL)!
    }
    override var baseURL: NSURL! {
        if let baseURL = _baseURLFromXML {
            return baseURL
        }
        return super.baseURL
    }
    
    // private
    private let _baseURLFromXML: NSURL?
    private let _relativeDescriptionURL: NSURL!
    private let _relativeControlURL: NSURL!
    private let _relativeEventURL: NSURL!
    
    // MARK: UPnP Event handling related
    lazy private var _eventObservers = [EventObserver]()
    private var _concurrentEventObserverQueue: dispatch_queue_t!
    private var _eventSubscription: Any?
    
    override init?(ssdpDevice: SSDPDBDevice_ObjC) {
        super.init(ssdpDevice: ssdpDevice)
        
        let serviceParser = UPnPServiceParser(upnpService: self)
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
        
        _concurrentEventObserverQueue = dispatch_queue_create("com.upnatom.abstract-upnp-service.event-observer-queue.\(usn.rawValue)", DISPATCH_QUEUE_CONCURRENT)
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
    
    private class func UPnPEventInfoKey() -> String {
        return "UPnPEventInfoKey"
    }
    
    func addEventObserver(queue: NSOperationQueue?, callBackBlock: (event: UPnPEvent) -> Void) -> AnyObject {
        let observer = EventObserver(notificationCenterObserver: NSNotificationCenter.defaultCenter().addObserverForName(UPnPEventReceivedNotification(), object: nil, queue: queue) { [unowned self] (notification: NSNotification!) -> Void in
            if let rawEventInfo = notification.userInfo?[AbstractUPnPService.UPnPEventInfoKey()] as? [String: String] {
                let event = self.createEvent(rawEventInfo)
                callBackBlock(event: event)
            }
        })
        
        dispatch_barrier_async(_concurrentEventObserverQueue, { () -> Void in
            self._eventObservers.append(observer)
            
            if self._eventObservers.count == 1 {
                // subscribe
                UPnPManager_Swift.sharedInstance.eventSubscriptionManager.subscribe(self, eventURL: self.eventURL, completion: { (subscription: Result<Any>) -> Void in
                    switch subscription {
                    case .Success(let value):
                        self._eventSubscription = value
                    case .Failure(let error):
                        let errorDescription = error.localizedDescription("Unknown subscribe error")
                        println("Unable to subscribe to UPnP events from \(self.eventURL): \(errorDescription)")
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
                        println("Unable to unsubscribe to UPnP events from \(self.eventURL): \(errorDescription)")
                        self._eventSubscription = nil
                    }
                })
            }
        })
    }
    
    func handleEvent(eventSubscriptionManager: UPnPEventSubscriptionManager, eventInfo: [String: String]) {
        NSNotificationCenter.defaultCenter().postNotificationName(UPnPEventReceivedNotification(), object: nil, userInfo: [AbstractUPnPService.UPnPEventInfoKey(): eventInfo])
    }
    
    /// overridable by service subclasses
    func createEvent(rawEventInfo: [String: String]) -> UPnPEvent {
        return UPnPEvent(rawEventInfo: rawEventInfo)
    }
}

extension AbstractUPnPService.EventObserver: Equatable { }

private func ==(lhs: AbstractUPnPService.EventObserver, rhs: AbstractUPnPService.EventObserver) -> Bool {
    return lhs.notificationCenterObserver === rhs.notificationCenterObserver
}

extension AbstractUPnPService: ExtendedPrintable {
    override var className: String { return "AbstractUPnPService" }
    override var description: String {
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
