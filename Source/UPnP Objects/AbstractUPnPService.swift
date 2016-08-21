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
import Ono
import AFNetworking

public class AbstractUPnPService: AbstractUPnP {
    // public
    public var serviceType: String {
        return urn
    }
    public private(set) var serviceID: String! // TODO: Should ideally be a constant, see Github issue #10
    public var serviceDescriptionURL: NSURL {
        return NSURL(string: _relativeServiceDescriptionURL.absoluteString, relativeToURL: baseURL)!
    }
    public var controlURL: NSURL {
        return NSURL(string: _relativeControlURL.absoluteString, relativeToURL: baseURL)!
    }
    public var eventURL: NSURL {
        return NSURL(string: _relativeEventURL.absoluteString, relativeToURL: baseURL)!
    }
    override public var baseURL: NSURL! {
        if let baseURL = _baseURLFromXML {
            return baseURL
        }
        return super.baseURL
    }
    public weak var deviceSource: UPnPDeviceSource?
    public var device: AbstractUPnPDevice? {
        return deviceSource?.device(forUSN: _deviceUSN)
    }
    
    /// protected
    public private(set) var soapSessionManager: SOAPSessionManager! // TODO: Should ideally be a constant, see Github issue #10
    
    // private
    private var _baseURLFromXML: NSURL? // TODO: Should ideally be a constant, see Github issue #10
    private var _relativeServiceDescriptionURL: NSURL! // TODO: Should ideally be a constant, see Github issue #10
    private var _relativeControlURL: NSURL! // TODO: Should ideally be a constant, see Github issue #10
    private var _relativeEventURL: NSURL! // TODO: Should ideally be a constant, see Github issue #10
    private var _deviceUSN: UniqueServiceName! // TODO: Should ideally be a constant, see Github issue #10
    private var _serviceDescriptionDocument: ONOXMLDocument?
    private static let _serviceDescriptionDefaultPrefix = "service"
    /// Must be accessed within dispatch_sync() or dispatch_async() and updated within dispatch_barrier_async() to the concurrent queue
    private var _soapActionsSupportCache = [String: Bool]()
    
    // MARK: UPnP Event handling related
    /// Must be accessed within dispatch_sync() or dispatch_async() and updated within dispatch_barrier_async() to the concurrent queue
    lazy private var _eventObservers = [EventObserver]()
    private var _concurrentEventObserverQueue: dispatch_queue_t!
    private var _concurrentSOAPActionsSupportCacheQueue = dispatch_queue_create("com.upnatom.abstract-upnp-service.soap-actions-support-cache-queue", DISPATCH_QUEUE_CONCURRENT)
    private weak var _eventSubscription: AnyObject?
    
    required public init?(usn: UniqueServiceName, descriptionURL: NSURL, descriptionXML: NSData) {
        super.init(usn: usn, descriptionURL: descriptionURL, descriptionXML: descriptionXML)
        
        soapSessionManager = SOAPSessionManager(baseURL: baseURL, sessionConfiguration: nil)
        
        _concurrentEventObserverQueue = dispatch_queue_create("com.upnatom.abstract-upnp-service.event-observer-queue.\(usn.rawValue)", DISPATCH_QUEUE_CONCURRENT)
        let serviceParser = UPnPServiceParser(upnpService: self, descriptionXML: descriptionXML)
        let parsedService = serviceParser.parse().value
        
        if let baseURL = parsedService?.baseURL {
            _baseURLFromXML = baseURL
        }
        
        guard let serviceID = parsedService?.serviceID,
            let relativeServiceDescriptionURL = parsedService?.relativeServiceDescriptionURL,
            let relativeControlURL = parsedService?.relativeControlURL,
            let relativeEventURL = parsedService?.relativeEventURL,
            let deviceUSN = parsedService?.deviceUSN else {
                return nil
        }
        
        self.serviceID = serviceID
        self._relativeServiceDescriptionURL = relativeServiceDescriptionURL
        self._relativeControlURL = relativeControlURL
        self._relativeEventURL = relativeEventURL
        self._deviceUSN = deviceUSN
    }
    
    deinit {
        // deinit may be called during init if init returns nil, queue var may not be set
        guard _concurrentEventObserverQueue != nil else {
            return
        }
        
        var eventObservers: [EventObserver]!
        dispatch_sync(_concurrentEventObserverQueue, { () -> Void in
            eventObservers = self._eventObservers
        })
        
        for eventObserver in eventObservers {
            NSNotificationCenter.defaultCenter().removeObserver(eventObserver.notificationCenterObserver)
        }
    }
    
    /// The service description document can be used for querying for service specific support i.e. SOAP action arguments
    public func serviceDescriptionDocument(completion: (serviceDescriptionDocument: ONOXMLDocument?, defaultPrefix: String) -> Void) {
        if let serviceDescriptionDocument = _serviceDescriptionDocument {
            completion(serviceDescriptionDocument: serviceDescriptionDocument, defaultPrefix: AbstractUPnPService._serviceDescriptionDefaultPrefix)
        } else {
            let httpSessionManager = AFHTTPSessionManager()
            httpSessionManager.requestSerializer = AFHTTPRequestSerializer()
            httpSessionManager.responseSerializer = AFHTTPResponseSerializer()
            httpSessionManager.GET(serviceDescriptionURL.absoluteString, parameters: nil, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    guard let xmlData = responseObject as? NSData else {
                        completion(serviceDescriptionDocument: nil, defaultPrefix: AbstractUPnPService._serviceDescriptionDefaultPrefix)
                        return
                    }
                    
                    do {
                        let serviceDescriptionDocument = try ONOXMLDocument(data: xmlData)
                        LogVerbose("Parsing service description XML:\nSTART\n\(NSString(data: xmlData, encoding: NSUTF8StringEncoding))\nEND")
                        
                        serviceDescriptionDocument.definePrefix(AbstractUPnPService._serviceDescriptionDefaultPrefix, forDefaultNamespace: "urn:schemas-upnp-org:service-1-0")
                        self._serviceDescriptionDocument = serviceDescriptionDocument
                        completion(serviceDescriptionDocument: serviceDescriptionDocument, defaultPrefix: AbstractUPnPService._serviceDescriptionDefaultPrefix)
                    } catch let parseError as NSError {
                        LogError("Failed to parse service description for SOAP action support check: \(parseError)")
                        completion(serviceDescriptionDocument: nil, defaultPrefix: AbstractUPnPService._serviceDescriptionDefaultPrefix)
                    }
                })
                }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                    LogError("Failed to retrieve service description for SOAP action support check: \(error)")
                    completion(serviceDescriptionDocument: nil, defaultPrefix: AbstractUPnPService._serviceDescriptionDefaultPrefix)
            })
        }
    }
    
    /// Used for determining support of optional SOAP actions for this service.
    public func supportsSOAPAction(actionParameters actionParameters: SOAPRequestSerializer.Parameters, completion: (isSupported: Bool) -> Void) {
        let soapActionName = actionParameters.soapAction
        
        // only reading SOAP actions support cache, so distpach_async is appropriate to allow for concurrent reads
        dispatch_async(_concurrentSOAPActionsSupportCacheQueue, { () -> Void in
            let soapActionsSupportCache = self._soapActionsSupportCache
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                if let isSupported = soapActionsSupportCache[soapActionName] {
                    completion(isSupported: isSupported)
                } else {
                    self.serviceDescriptionDocument { (serviceDescriptionDocument: ONOXMLDocument?, defaultPrefix: String) -> Void in
                        if let serviceDescriptionDocument = serviceDescriptionDocument {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                                // For better performance, check the action name only for now. If this proves inadequite in the future the argument list can also be compared with the SOAP parameters passed in.
                                let prefix = defaultPrefix
                                let xPathQuery = "/\(prefix):scpd/\(prefix):actionList/\(prefix):action[\(prefix):name='\(soapActionName)']"
                                let isSupported = serviceDescriptionDocument.firstChildWithXPath(xPathQuery) != nil ? true : false
                                
                                dispatch_barrier_async(self._concurrentSOAPActionsSupportCacheQueue) { () -> Void in
                                    self._soapActionsSupportCache[soapActionName] = isSupported
                                }
                                
                                completion(isSupported: isSupported)
                            }
                        } else {
                            // Failed to retrieve service description. This result does not warrant recording false in the cache as the service description may still show the action as supported when retreived in a subsequent attempt.
                            completion(isSupported: false)
                        }
                    }
                }
            }
        })
    }
    
    /// overridable by service subclasses
    public func createEvent(eventXML: NSData) -> UPnPEvent {
        return UPnPEvent(eventXML: eventXML, service: self)
    }
}

// MARK: UPnP Event handling

extension AbstractUPnPService: UPnPEventSubscriber {
    private static let _upnpEventKey = "UPnPEventKey"
    
    private class EventObserver {
        let notificationCenterObserver: AnyObject
        init(notificationCenterObserver: AnyObject) {
            self.notificationCenterObserver = notificationCenterObserver
        }
    }
    
    private func UPnPEventReceivedNotification() -> String {
        return "UPnPEventReceivedNotification.\(usn.rawValue)"
    }
    
    /// Returns an opaque object to act as the observer. Use it when the event observer needs to be removed.
    public func addEventObserver(queue: NSOperationQueue?, callBackBlock: (event: UPnPEvent) -> Void) -> AnyObject {
        /// Use callBackBlock for event notifications. While the notifications are backed by NSNotifications for broadcasting, they should only be used internally in order to keep track of how many subscribers there are.
        let observer = EventObserver(notificationCenterObserver: NSNotificationCenter.defaultCenter().addObserverForName(UPnPEventReceivedNotification(), object: nil, queue: queue) { (notification: NSNotification!) -> Void in
            if let event = notification.userInfo?[AbstractUPnPService._upnpEventKey] as? UPnPEvent {
                callBackBlock(event: event)
            }
        })
        
        dispatch_barrier_async(_concurrentEventObserverQueue, { () -> Void in
            self._eventObservers.append(observer)
            
            if self._eventObservers.count >= 1 {
                // subscribe
                UPnPEventSubscriptionManager.sharedInstance.subscribe(self, eventURL: self.eventURL, completion: { (subscription: Result<AnyObject>) -> Void in
                    switch subscription {
                    case .Success(let value):
                        self._eventSubscription = value
                    case .Failure(let error):
                        let errorDescription = error.localizedDescription("Unknown subscribe error")
                        LogError("Unable to subscribe to UPnP events from \(self.eventURL): \(errorDescription)")
                    }
                })
            }
        })
        
        return observer
    }
    
    public func removeEventObserver(observer: AnyObject) {
        dispatch_barrier_async(_concurrentEventObserverQueue, { () -> Void in
            if let observer = observer as? EventObserver {
                self._eventObservers.removeObject(observer)
                NSNotificationCenter.defaultCenter().removeObserver(observer.notificationCenterObserver)
            }
            
            if self._eventObservers.count == 0 {
                // unsubscribe
                if let eventSubscription: AnyObject = self._eventSubscription {
                    self._eventSubscription = nil
                    
                    UPnPEventSubscriptionManager.sharedInstance.unsubscribe(eventSubscription, completion: { (result: EmptyResult) -> Void in
                        if let error = result.error {
                            let errorDescription = error.localizedDescription("Unknown unsubscribe error")
                            LogError("Unable to unsubscribe to UPnP events from \(self.eventURL): \(errorDescription)")
                        }
                    })
                }
            }
        })
    }
    
    func handleEvent(eventSubscriptionManager: UPnPEventSubscriptionManager, eventXML: NSData) {
        NSNotificationCenter.defaultCenter().postNotificationName(UPnPEventReceivedNotification(), object: nil, userInfo: [AbstractUPnPService._upnpEventKey: self.createEvent(eventXML)])
    }
    
    func subscriptionDidFail(eventSubscriptionManager: UPnPEventSubscriptionManager) {
        LogWarn("Event subscription did fail for service: \(self)")
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

/// overrides ExtendedPrintable protocol implementation
extension AbstractUPnPService {
    override public var className: String { return "\(self.dynamicType)" }
    override public var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        properties.add("deviceUSN", property: _deviceUSN)
        properties.add("serviceType", property: serviceType)
        properties.add("serviceID", property: serviceID)
        properties.add("serviceDescriptionURL", property: serviceDescriptionURL.absoluteString)
        properties.add("controlURL", property: controlURL.absoluteString)
        properties.add("eventURL", property: eventURL.absoluteString)
        return properties.description
    }
}

@objc public protocol UPnPDeviceSource: class {
    func device(forUSN usn: UniqueServiceName) -> AbstractUPnPDevice?
}

class UPnPServiceParser: AbstractSAXXMLParser {
    /// Using a class instead of struct since it's much easier and safer to continuously update from references rather than values directly as it's easy to accidentally update a copy and not the original.
    class ParserUPnPService {
        var baseURL: NSURL?
        var serviceType: String?
        var serviceID: String?
        var relativeServiceDescriptionURL: NSURL?
        var relativeControlURL: NSURL?
        var relativeEventURL: NSURL?
        var deviceUSN: UniqueServiceName?
    }
    
    private unowned let _upnpService: AbstractUPnPService
    private let _descriptionXML: NSData
    private var _baseURL: NSURL?
    private var _deviceType: String?
    private var _currentParserService: ParserUPnPService?
    private var _foundParserService: ParserUPnPService?
    
    init(supportNamespaces: Bool, upnpService: AbstractUPnPService, descriptionXML: NSData) {
        self._upnpService = upnpService
        self._descriptionXML = descriptionXML
        super.init(supportNamespaces: supportNamespaces)
        
        /// NOTE: URLBase is deprecated in UPnP v2.0, baseURL should be derived from the SSDP discovery description URL
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["root", "URLBase"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._baseURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "deviceType"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._deviceType = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service"], didStartParsingElement: { (elementName, attributeDict) -> Void in
            self._currentParserService = ParserUPnPService()
            }, didEndParsingElement: { (elementName) -> Void in
                if let serviceType = self._currentParserService?.serviceType where serviceType == self._upnpService.urn {
                    self._foundParserService = self._currentParserService
                }
            }, foundInnerText: nil))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "serviceType"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentService = self._currentParserService
            currentService?.serviceType = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "serviceId"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentService = self._currentParserService
            currentService?.serviceID = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "SCPDURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentService = self._currentParserService
            currentService?.relativeServiceDescriptionURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "controlURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentService = self._currentParserService
            currentService?.relativeControlURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "eventSubURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentService = self._currentParserService
            currentService?.relativeEventURL = NSURL(string: text)
        }))
    }
    
    convenience init(upnpService: AbstractUPnPService, descriptionXML: NSData) {
        self.init(supportNamespaces: false, upnpService: upnpService, descriptionXML: descriptionXML)
    }
    
    func parse() -> Result<ParserUPnPService> {
        switch super.parse(data: _descriptionXML) {
        case .Success:
            if let foundParserService = _foundParserService {
                foundParserService.baseURL = _baseURL
                if let deviceType = _deviceType {
                    foundParserService.deviceUSN = UniqueServiceName(uuid: _upnpService.uuid, urn: deviceType)
                }
                return .Success(foundParserService)
            } else {
                return .Failure(createError("Parser error"))
            }
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
