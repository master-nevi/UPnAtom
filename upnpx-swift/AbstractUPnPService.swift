//
//  AbstractUPnPService.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class AbstractUPnPService_Swift: AbstractUPnP_Swift {
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
    lazy private var _eventObservers = [UPnPEventObserver]()
    private var _concurrentDeviceQueue: dispatch_queue_t!
    
    override init?(ssdpDevice: SSDPDBDevice_ObjC) {
        super.init(ssdpDevice: ssdpDevice)
        
        let serviceParser = UPnPServiceParser_Swift(upnpService: self)
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
        
        _concurrentDeviceQueue = dispatch_queue_create("com.upnpx-swift.upnpEventQueue.\(serviceType)", DISPATCH_QUEUE_CONCURRENT)
    }
}

// MARK: UPnP Event handling

extension AbstractUPnPService_Swift {
    class UPnPEventObserver {
        let notificationCenterObserver: AnyObject
        init(notificationCenterObserver: AnyObject) {
            self.notificationCenterObserver = notificationCenterObserver
        }
    }
    
    private class func UPnPEventReceivedNotification() -> String {
        return "UPnPEventReceivedNotification"
    }
    
    private class func UPnPEventInfoKey() -> String {
        return "UPnPEventInfoKey"
    }
    
    func addEventObserver(queue: NSOperationQueue?, callBackBlock: (UPnPEvent_Swift) -> Void) -> AnyObject {
        let observer = UPnPEventObserver(notificationCenterObserver: NSNotificationCenter.defaultCenter().addObserverForName(AbstractUPnPService_Swift.UPnPEventReceivedNotification(), object: nil, queue: queue) { [unowned self] (notification: NSNotification!) -> Void in
            if let rawEventInfo = notification.userInfo?[AbstractUPnPService_Swift.UPnPEventInfoKey()] as? [String: String] {
                let event = self.createEvent(rawEventInfo)
                callBackBlock(event)
            }
        })
        
        dispatch_barrier_async(_concurrentDeviceQueue, { () -> Void in
            self._eventObservers.append(observer)
            
            if self._eventObservers.count == 1 {
                // subscribe
            }
        })
        
        return observer
    }
    
    func removeEventObserver(observer: AnyObject) {
        dispatch_barrier_async(_concurrentDeviceQueue, { () -> Void in
            if let observer = observer as? UPnPEventObserver {
                removeObject(&self._eventObservers, observer)
                NSNotificationCenter.defaultCenter().removeObserver(observer.notificationCenterObserver)
            }
            
            if self._eventObservers.count == 0 {
                // unsubscribe
            }
        })
    }
    
    /// overridable by service subclasses
    func createEvent(rawEventInfo: [String: String]) -> UPnPEvent_Swift {
        return UPnPEvent_Swift(rawEventInfo: rawEventInfo)
    }
}

extension AbstractUPnPService_Swift.UPnPEventObserver: Equatable { }

func ==(lhs: AbstractUPnPService_Swift.UPnPEventObserver, rhs: AbstractUPnPService_Swift.UPnPEventObserver) -> Bool {
    return lhs.notificationCenterObserver === rhs.notificationCenterObserver
}

extension AbstractUPnPService_Swift: ExtendedPrintable {
    override var className: String { return "AbstractUPnPService_Swift" }
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
