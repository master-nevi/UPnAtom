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

open class AbstractUPnPService: AbstractUPnP {
    // public
    open var serviceType: String {
        return urn
    }
    open fileprivate(set) var serviceID: String! // TODO: Should ideally be a constant, see Github issue #10
    open var serviceDescriptionURL: URL {
        return (URL(string: _relativeServiceDescriptionURL.absoluteString, relativeTo: baseURL)?.absoluteURL)!
    }
    open var controlURL: URL {
        return (URL(string: _relativeControlURL.absoluteString, relativeTo: baseURL)?.absoluteURL)!
    }
    open var eventURL: URL {
        return (URL(string: _relativeEventURL.absoluteString, relativeTo: baseURL)?.absoluteURL)!
    }
    override open var baseURL: URL! {
        if let baseURL = _baseURLFromXML {
            return baseURL
        }
        return super.baseURL as URL!
    }
    open weak var deviceSource: UPnPDeviceSource?
    open var device: AbstractUPnPDevice? {
        return deviceSource?.device(forUSN: _deviceUSN)
    }
    
    /// protected
    open fileprivate(set) var soapSessionManager: SOAPSessionManager! // TODO: Should ideally be a constant, see Github issue #10
    
    // private
    fileprivate var _baseURLFromXML: URL? // TODO: Should ideally be a constant, see Github issue #10
    fileprivate var _relativeServiceDescriptionURL: URL! // TODO: Should ideally be a constant, see Github issue #10
    fileprivate var _relativeControlURL: URL! // TODO: Should ideally be a constant, see Github issue #10
    fileprivate var _relativeEventURL: URL! // TODO: Should ideally be a constant, see Github issue #10
    fileprivate var _deviceUSN: UniqueServiceName! // TODO: Should ideally be a constant, see Github issue #10
    fileprivate var _serviceDescriptionDocument: ONOXMLDocument?
    fileprivate static let _serviceDescriptionDefaultPrefix = "service"
    /// Must be accessed within dispatch_sync() or dispatch_async() and updated within dispatch_barrier_async() to the concurrent queue
    fileprivate var _soapActionsSupportCache = [String: Bool]()
    
    // MARK: UPnP Event handling related
    /// Must be accessed within dispatch_sync() or dispatch_async() and updated within dispatch_barrier_async() to the concurrent queue
    lazy fileprivate var _eventObservers = [EventObserver]()
    fileprivate var _concurrentEventObserverQueue: DispatchQueue!
    fileprivate var _concurrentSOAPActionsSupportCacheQueue = DispatchQueue(label: "com.upnatom.abstract-upnp-service.soap-actions-support-cache-queue", attributes: DispatchQueue.Attributes.concurrent)
    fileprivate weak var _eventSubscription: AnyObject?
    
    required public init?(usn: UniqueServiceName, descriptionURL: URL, descriptionXML: Data) {
        super.init(usn: usn, descriptionURL: descriptionURL, descriptionXML: descriptionXML)
        
        soapSessionManager = SOAPSessionManager(baseURL: baseURL, sessionConfiguration: nil)
        
        _concurrentEventObserverQueue = DispatchQueue(label: "com.upnatom.abstract-upnp-service.event-observer-queue.\(usn.rawValue)", attributes: DispatchQueue.Attributes.concurrent)
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

    /* Comment for confliction method swift 3.2 + unusage
    required public init?(usn: UniqueServiceName, descriptionURL: NSURL, descriptionXML: NSData) {
        fatalError("init(usn:descriptionURL:descriptionXML:) has not been implemented")
    } */
    
    deinit {
        // deinit may be called during init if init returns nil, queue var may not be set
        guard _concurrentEventObserverQueue != nil else {
            return
        }
        
        var eventObservers: [EventObserver]!
        _concurrentEventObserverQueue.sync(execute: { () -> Void in
            eventObservers = self._eventObservers
        })
        
        for eventObserver in eventObservers {
            NotificationCenter.default.removeObserver(eventObserver.notificationCenterObserver)
        }
    }
    
    /// The service description document can be used for querying for service specific support i.e. SOAP action arguments
    open func serviceDescriptionDocument(_ completion: @escaping (_ serviceDescriptionDocument: ONOXMLDocument?, _ defaultPrefix: String) -> Void) {
        if let serviceDescriptionDocument = _serviceDescriptionDocument {
            completion(serviceDescriptionDocument, AbstractUPnPService._serviceDescriptionDefaultPrefix)
        } else {
            let httpSessionManager = AFHTTPSessionManager()
            httpSessionManager.requestSerializer = AFHTTPRequestSerializer()
            httpSessionManager.responseSerializer = AFHTTPResponseSerializer()
            httpSessionManager.get(serviceDescriptionURL.absoluteString, parameters: nil, success: { (task, responseObject) in
                DispatchQueue.global(qos: .default).async(execute: { 
                    guard let xmlData = responseObject as? NSData else {
                        completion(nil, AbstractUPnPService._serviceDescriptionDefaultPrefix)
                        return
                    }
                    
                    do {
                        let serviceDescriptionDocument = try ONOXMLDocument(data: xmlData as Data!)
                        LogVerbose("Parsing service description XML:\nSTART\n\(NSString(data: xmlData as Data, encoding: String.Encoding.utf8.rawValue))\nEND")
                        
                        serviceDescriptionDocument.definePrefix(AbstractUPnPService._serviceDescriptionDefaultPrefix, forDefaultNamespace: "urn:schemas-upnp-org:service-1-0")
                        self._serviceDescriptionDocument = serviceDescriptionDocument
                        completion(serviceDescriptionDocument, AbstractUPnPService._serviceDescriptionDefaultPrefix)
                    } catch let parseError as NSError {
                        LogError("Failed to parse service description for SOAP action support check: \(parseError)")
                        completion(nil, AbstractUPnPService._serviceDescriptionDefaultPrefix)
                    }
                })
            }, failure: { (task, error) in
                LogError("Failed to retrieve service description for SOAP action support check: \(error)")
                completion(nil, AbstractUPnPService._serviceDescriptionDefaultPrefix)
            })
        }
    }
    
    /// Used for determining support of optional SOAP actions for this service.
    open func supportsSOAPAction(actionParameters: SOAPRequestSerializer.Parameters, completion: @escaping (_ isSupported: Bool) -> Void) {
        let soapActionName = actionParameters.soapAction
        
        // only reading SOAP actions support cache, so distpach_async is appropriate to allow for concurrent reads
        _concurrentSOAPActionsSupportCacheQueue.async(execute: { () -> Void in
            let soapActionsSupportCache = self._soapActionsSupportCache
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async { () -> Void in
                if let isSupported = soapActionsSupportCache[soapActionName] {
                    completion(isSupported)
                } else {
                    self.serviceDescriptionDocument { (serviceDescriptionDocument: ONOXMLDocument?, defaultPrefix: String) -> Void in
                        if let serviceDescriptionDocument = serviceDescriptionDocument {
                            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async { () -> Void in
                                // For better performance, check the action name only for now. If this proves inadequite in the future the argument list can also be compared with the SOAP parameters passed in.
                                let prefix = defaultPrefix
                                let xPathQuery = "/\(prefix):scpd/\(prefix):actionList/\(prefix):action[\(prefix):name='\(soapActionName)']"
                                let isSupported = serviceDescriptionDocument.firstChild(withXPath: xPathQuery) != nil ? true : false
                                
                                self._concurrentSOAPActionsSupportCacheQueue.async(flags: .barrier, execute: { () -> Void in
                                    self._soapActionsSupportCache[soapActionName] = isSupported
                                }) 
                                
                                completion(isSupported)
                            }
                        } else {
                            // Failed to retrieve service description. This result does not warrant recording false in the cache as the service description may still show the action as supported when retreived in a subsequent attempt.
                            completion(false)
                        }
                    }
                }
            }
        })
    }
    
    /// overridable by service subclasses
    open func createEvent(_ eventXML: Data) -> UPnPEvent {
        return UPnPEvent(eventXML: eventXML, service: self)
    }
}

// MARK: UPnP Event handling

extension AbstractUPnPService: UPnPEventSubscriber {
    fileprivate static let _upnpEventKey = "UPnPEventKey"
    
    fileprivate class EventObserver {
        let notificationCenterObserver: AnyObject
        init(notificationCenterObserver: AnyObject) {
            self.notificationCenterObserver = notificationCenterObserver
        }
    }
    
    fileprivate func UPnPEventReceivedNotification() -> String {
        return "UPnPEventReceivedNotification.\(usn.rawValue)"
    }
    
    /// Returns an opaque object to act as the observer. Use it when the event observer needs to be removed.
    public func addEventObserver(_ queue: OperationQueue?, callBackBlock: @escaping (_ event: UPnPEvent) -> Void) -> AnyObject {
        /// Use callBackBlock for event notifications. While the notifications are backed by NSNotifications for broadcasting, they should only be used internally in order to keep track of how many subscribers there are.
        let observer = EventObserver(notificationCenterObserver: NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: UPnPEventReceivedNotification()), object: nil, queue: queue) { (notification: Notification!) -> Void in
            if let event = notification.userInfo?[AbstractUPnPService._upnpEventKey] as? UPnPEvent {
                callBackBlock(event)
            }
        })
        
        _concurrentEventObserverQueue.async(flags: .barrier, execute: { () -> Void in
            self._eventObservers.append(observer)
            
            if self._eventObservers.count >= 1 {
                // subscribe
                UPnPEventSubscriptionManager.sharedInstance.subscribe(self, eventURL: self.eventURL, completion: { (subscription: Result<AnyObject>) -> Void in
                    switch subscription {
                    case .success(let value):
                        self._eventSubscription = value
                    case .failure(let error):
                        let errorDescription = error.localizedDescription("Unknown subscribe error")
                        LogError("Unable to subscribe to UPnP events from \(self.eventURL): \(errorDescription)")
                    }
                })
            }
        })
        
        return observer
    }
    
    public func removeEventObserver(_ observer: AnyObject) {
        _concurrentEventObserverQueue.async(flags: .barrier, execute: { () -> Void in
            if let observer = observer as? EventObserver {
                self._eventObservers.removeObject(observer)
                NotificationCenter.default.removeObserver(observer.notificationCenterObserver)
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
    
    func handleEvent(_ eventSubscriptionManager: UPnPEventSubscriptionManager, eventXML: Data) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: UPnPEventReceivedNotification()), object: nil, userInfo: [AbstractUPnPService._upnpEventKey: self.createEvent(eventXML)])
    }
    
    func subscriptionDidFail(_ eventSubscriptionManager: UPnPEventSubscriptionManager) {
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
    override public var className: String { return "\(type(of: self))" }
    override open var description: String {
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
        var baseURL: URL?
        var serviceType: String?
        var serviceID: String?
        var relativeServiceDescriptionURL: URL?
        var relativeControlURL: URL?
        var relativeEventURL: URL?
        var deviceUSN: UniqueServiceName?
    }
    
    fileprivate unowned let _upnpService: AbstractUPnPService
    fileprivate let _descriptionXML: Data
    fileprivate var _baseURL: URL?
    fileprivate var _deviceType: String?
    fileprivate var _currentParserService: ParserUPnPService?
    fileprivate var _foundParserService: ParserUPnPService?
    
    init(supportNamespaces: Bool, upnpService: AbstractUPnPService, descriptionXML: Data) {
        self._upnpService = upnpService
        self._descriptionXML = descriptionXML
        super.init(supportNamespaces: supportNamespaces)
        
        /// NOTE: URLBase is deprecated in UPnP v2.0, baseURL should be derived from the SSDP discovery description URL
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["root", "URLBase"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._baseURL = URL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "deviceType"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._deviceType = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service"], didStartParsingElement: { (elementName, attributeDict) -> Void in
            self._currentParserService = ParserUPnPService()
            }, didEndParsingElement: { (elementName) -> Void in
                if let serviceType = self._currentParserService?.serviceType, serviceType == self._upnpService.urn {
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
            currentService?.relativeServiceDescriptionURL = URL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "controlURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentService = self._currentParserService
            currentService?.relativeControlURL = URL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "eventSubURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentService = self._currentParserService
            currentService?.relativeEventURL = URL(string: text)
        }))
    }
    
    convenience init(upnpService: AbstractUPnPService, descriptionXML: Data) {
        self.init(supportNamespaces: false, upnpService: upnpService, descriptionXML: descriptionXML)
    }
    
    func parse() -> Result<ParserUPnPService> {
        switch super.parse(data: _descriptionXML) {
        case .success:
            if let foundParserService = _foundParserService {
                foundParserService.baseURL = _baseURL
                if let deviceType = _deviceType {
                    foundParserService.deviceUSN = UniqueServiceName(uuid: _upnpService.uuid, urn: deviceType)
                }
                return .success(foundParserService)
            } else {
                return .failure(createError("Parser error"))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}
