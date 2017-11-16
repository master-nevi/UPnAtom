//
//  UPnPEventSubscriptionManager.swift
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
import GCDWebServer

protocol UPnPEventSubscriber: class {
    func handleEvent(_ eventSubscriptionManager: UPnPEventSubscriptionManager, eventXML: Data)
    func subscriptionDidFail(_ eventSubscriptionManager: UPnPEventSubscriptionManager)
}

class UPnPEventSubscriptionManager {
    // Subclasses NSObject in order to filter collections of this class using NSPredicate
    class Subscription: NSObject {
        fileprivate(set) var subscriptionID: String
        fileprivate(set) var expiration: Date
        weak var subscriber: UPnPEventSubscriber?
        let eventURLString: String
        fileprivate unowned let _manager: UPnPEventSubscriptionManager
        fileprivate var _renewDate: Date {
            return expiration.addingTimeInterval(-30) // attempt renewal 30 seconds before expiration
        }
        fileprivate var _renewWarningTimer: Timer?
        fileprivate var _expirationTimer: Timer?
        
        init(subscriptionID: String, expiration: Date, subscriber: UPnPEventSubscriber, eventURLString: String, manager: UPnPEventSubscriptionManager) {
            self.subscriptionID = subscriptionID
            self.expiration = expiration
            self.subscriber = subscriber
            self.eventURLString = eventURLString
            _manager = manager
            
            super.init()
            
            updateTimers()
        }
        
        func invalidate() {
            _renewWarningTimer?.invalidate()
            _expirationTimer?.invalidate()
        }
        
        func update(_ subscriptionID: String, expiration: Date) {
            self.invalidate()
            
            self.subscriptionID = subscriptionID
            self.expiration = expiration
            updateTimers()
        }
        
        fileprivate func updateTimers() {
            let renewDate = _renewDate
            let expiration = self.expiration
            
            DispatchQueue.main.async(execute: { () -> Void in
                self._renewWarningTimer = Timer.scheduledTimerWithTimeInterval(renewDate.timeIntervalSinceNow, repeats: false, closure: { [weak self] () -> Void in
                    if let strongSelf = self {
                        strongSelf._manager.subscriptionNeedsRenewal(strongSelf)
                    }
                })
                
                self._expirationTimer = Timer.scheduledTimerWithTimeInterval(expiration.timeIntervalSinceNow, repeats: false, closure: { [weak self] () -> Void in
                    if let strongSelf = self {
                        strongSelf._manager.subscriptionDidExpire(strongSelf)
                    }
                })
            })
        }
    }
    
    // internal
    static let sharedInstance = UPnPEventSubscriptionManager()
    
    // private
    /// Must be accessed within dispatch_sync() or dispatch_async() and updated within dispatch_barrier_async() to the concurrent queue
    fileprivate var _subscriptions = [String: Subscription]() /* [eventURLString: Subscription] */
    fileprivate let _concurrentSubscriptionQueue = DispatchQueue(label: "com.upnatom.upnp-event-subscription-manager.subscription-queue", attributes: DispatchQueue.Attributes.concurrent)
    /// Must be accessed within the subscription manager's concurrent queue
    fileprivate var _httpServer: GCDWebServer! // TODO: Should ideally be a constant, non-optional, see Github issue #10
    fileprivate let _httpServerPort: UInt = 52808
    fileprivate let _subscribeSessionManager = AFHTTPSessionManager()
    fileprivate let _renewSubscriptionSessionManager = AFHTTPSessionManager()
    fileprivate let _unsubscribeSessionManager = AFHTTPSessionManager()
    fileprivate let _defaultSubscriptionTimeout: Int = 1800
    fileprivate let _eventCallBackPath = "/Event/\(UUID().dashlessUUIDString)"
    
    init() {
        _subscribeSessionManager.requestSerializer = UPnPEventSubscribeRequestSerializer()
        _subscribeSessionManager.responseSerializer = UPnPEventSubscribeResponseSerializer()
        
        _renewSubscriptionSessionManager.requestSerializer = UPnPEventRenewSubscriptionRequestSerializer()
        _renewSubscriptionSessionManager.responseSerializer = UPnPEventRenewSubscriptionResponseSerializer()
        
        _unsubscribeSessionManager.requestSerializer = UPnPEventUnsubscribeRequestSerializer()
        _unsubscribeSessionManager.responseSerializer = UPnPEventUnsubscribeResponseSerializer()
        
        #if os(iOS)
            NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        #endif
        
        /// GCDWebServer must be initialized on the main thread. In order to guarantee this, it's initialization is dispatched on the main queue. To prevent critical sections from accessing it before it is initialized, the dispatch is synchronized within a dispatch barrier to the subscription manager's critical section queue.
        _concurrentSubscriptionQueue.async(flags: .barrier, execute: { () -> Void in
            DispatchQueue.main.sync(execute: { () -> Void in
                self._httpServer = GCDWebServer()
                
                GCDWebServer.setLogLevel(Int32(3))
                
                self._httpServer.addHandler(forMethod: "NOTIFY", path: self._eventCallBackPath, request: GCDWebServerDataRequest.self) { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
                    if let dataRequest = request as? GCDWebServerDataRequest,
                        let headers = dataRequest.headers as? [String: AnyObject],
                        let sid = headers["SID"] as? String,
                        let data = dataRequest.data {
                            LogVerbose("NOTIFY request: Final body with size: \(data.count)\nAll headers: \(headers)")
                            self.handleIncomingEvent(subscriptionID: sid, eventData: data)
                    }
                    
                    return GCDWebServerResponse()
                }
            })
        })
    }
    
    /// Subscribers should hold on to a weak reference of the subscription object returned. It's ok to call subscribe for a subscription that already exists, the subscription will simply be looked up and returned.
    func subscribe(_ subscriber: UPnPEventSubscriber, eventURL: URL, completion: ((_ result: Result<AnyObject>) -> Void)? = nil) {
        let failureClosure = { (error: NSError) -> Void in
            if let completion = completion {
                completion(.failure(error))
            }
        }
        
        guard let eventURLString: String? = eventURL.absoluteString else {
            failureClosure(createError("Event URL does not exist"))
            return
        }
        
        // check if subscription for event URL already exists
        subscriptions { [unowned self] (subscriptions: [String: Subscription]) -> Void in
            if let subscription = subscriptions[eventURLString!] {
                if let completion = completion {
                    completion(Result.success(subscription))
                }
                return
            }
            
            self.eventCallBackURL({ [unowned self] (eventCallBackURL: URL?) -> Void in
                guard let eventCallBackURL: URL = eventCallBackURL else {
                    failureClosure(createError("Event call back URL could not be created"))
                    return
                }
                
                LogInfo("event callback url: \(eventCallBackURL)")
                
                let parameters = UPnPEventSubscribeRequestSerializer.Parameters(callBack: eventCallBackURL, timeout: self._defaultSubscriptionTimeout)
                
                self._subscribeSessionManager.SUBSCRIBE(eventURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
                    guard let response: UPnPEventSubscribeResponseSerializer.Response = responseObject as? UPnPEventSubscribeResponseSerializer.Response else {
                        failureClosure(createError("Failure serializing event subscribe response"))
                        return
                    }
                    
                    let now = NSDate()
                    let expiration = now.addingTimeInterval(TimeInterval(response.timeout))
                    
                    let subscription = Subscription(subscriptionID: response.subscriptionID, expiration: expiration as Date, subscriber: subscriber, eventURLString: eventURL.absoluteString, manager: self)
                    
                    LogInfo("Successfully subscribed with timeout: \(response.timeout/60) mins: \(subscription)")
                    
                    self.add(subscription: subscription, completion: { () -> Void in
                        if let completion = completion {
                            completion(Result.success(subscription))
                        }
                    })
                    }, failure: { (task: URLSessionDataTask?, error: NSError) -> Void in
                        LogError("Failed to subscribe to event URL: \(eventURL.absoluteString)\nerror: \(error)")
                        failureClosure(error)
                })
            })
        }
    }
    
    func unsubscribe(_ subscription: AnyObject, completion: ((_ result: EmptyResult) -> Void)? = nil) {
        guard let subscription: Subscription = subscription as? Subscription else {
            if let completion = completion {
                completion(.failure(createError("Failure using subscription object passed in")))
            }
            return
        }
        
        // remove local version of subscription immediately to prevent any race conditions
        self.remove(subscription: subscription, completion: { [unowned self] () -> Void in
            let parameters = UPnPEventUnsubscribeRequestSerializer.Parameters(subscriptionID: subscription.subscriptionID)
            
            self._unsubscribeSessionManager.UNSUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task, responseObject) -> Void in
                LogInfo("Successfully unsubscribed: \(subscription)")
                if let completion = completion {
                    completion(.success)
                }
                
                }, failure: { (task, error) -> Void in
                    LogError("Failed to unsubscribe: \(subscription)\nerror: \(error)")
                    if let completion = completion {
                        completion(.failure(error))
                    }
            })
        })
    }
    
    fileprivate func handleIncomingEvent(subscriptionID: String, eventData: Data) {
        subscriptions { (subscriptions: [String: Subscription]) -> Void in
            if let subscription: Subscription = (Array(subscriptions.values) as NSArray).firstUsingPredicate(NSPredicate(format: "subscriptionID = %@", subscriptionID)) {
                DispatchQueue.main.async(execute: { () -> Void in
                    subscription.subscriber?.handleEvent(self, eventXML: eventData)
                    return
                })
            }
        }
    }
    
    @objc fileprivate func applicationDidEnterBackground(_ notification: Notification) {
        // GCDWebServer handles stopping and restarting itself as appropriate during application life cycle events. Invalidating the timers is all that's necessary here :)
        
        subscriptions { (subscriptions: [String: Subscription]) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                // invalidate all timers before being backgrounded as the will be trashed upon foregrounding anyways
                for (_, subscription) in subscriptions {
                    subscription.invalidate()
                }
            })
        }
    }
    
    @objc fileprivate func applicationWillEnterForeground(_ notification: Notification) {
        subscriptions { [unowned self] (subscriptions: [String: Subscription]) -> Void in
            // unsubscribe and re-subscribe for all event subscriptions
            for (_, subscription) in subscriptions {
                self.unsubscribe(subscription, completion: { (result) -> Void in
                    self.resubscribe(subscription, completion: {
                        if let errorDescription = $0.error?.localizedDescriptionOrNil {
                            LogError("\(errorDescription)")
                        }
                    })
                })
            }            
        }
    }
    
    fileprivate func add(subscription: Subscription, completion: (() -> Void)? = nil) {
        self._concurrentSubscriptionQueue.async(flags: .barrier, execute: { () -> Void in
            self._subscriptions[subscription.eventURLString] = subscription
            self.startStopHTTPServerIfNeeded(self._subscriptions.count)
            
            if let completion = completion {
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
                    completion()
                })
            }
        })
    }
    
    fileprivate func remove(subscription: Subscription, completion: (() -> Void)? = nil) {
        self._concurrentSubscriptionQueue.async(flags: .barrier, execute: { () -> Void in
            self._subscriptions.removeValue(forKey: subscription.eventURLString)?.invalidate()
            self.startStopHTTPServerIfNeeded(self._subscriptions.count)
            
            if let completion = completion {
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
                    completion()
                })
            }
        })
    }
    
    fileprivate func eventCallBackURL(_ closure: @escaping (_ eventCallBackURL: URL?) -> Void) {
        // only reading subscriptions, so distpach_async is appropriate to allow for concurrent reads
        self._concurrentSubscriptionQueue.async(execute: { () -> Void in
            // needs to be running in order to get server url for the subscription message
            let httpServer = self._httpServer
            var serverURL: URL? = httpServer?.serverURL
            
            // most likely nil if the http server is stopped
            if serverURL == nil && !(httpServer?.isRunning)! {
                // Start http server
                if self.startHTTPServer() {
                    // Grab server url
                    serverURL = httpServer?.serverURL
                    
                    // Stop http server if it's not needed further
                    self.startStopHTTPServerIfNeeded(self._subscriptions.count)
                } else {
                    LogError("Error starting HTTP server")
                }
            }
            
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
                serverURL != nil ? closure(URL(string: self._eventCallBackPath, relativeTo: serverURL)!) : closure(nil)
            })
        })
    }
    
    /// Safe to call from any queue and closure is called on callback queue
    fileprivate func subscriptions(_ closure: @escaping (_ subscriptions: [String: Subscription]) -> Void) {
        // only reading subscriptions, so distpach_async is appropriate to allow for concurrent reads
        self._concurrentSubscriptionQueue.async(execute: { () -> Void in
            let subscriptions = self._subscriptions
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
                closure(subscriptions)
            })
        })
    }
    
    /// Must be called with the most up to date knowledge of the subscription count so should be called withing the subscription queue.
    // TODO: consider putting entire method inside a dispatch_barrier_async to subscription queue
    fileprivate func startStopHTTPServerIfNeeded(_ subscriptionCount: Int) {
        let httpServer = self._httpServer
        if subscriptionCount == 0 && (httpServer?.isRunning)! {
            if !stopHTTPServer() {
                LogError("Error stopping HTTP server")
            }
        } else if subscriptionCount > 0 && !(httpServer?.isRunning)! {
            if !startHTTPServer() {
                LogError("Error starting HTTP server")
            }
        }
    }
    
    fileprivate func renewSubscription(_ subscription: Subscription, completion: ((_ result: Result<AnyObject>) -> Void)? = nil) {
        guard subscription.subscriber != nil else {
            if let completion = completion {
                completion(.failure(createError("Subscriber doesn't exist anymore")))
            }
            return
        }
        
        let parameters = UPnPEventRenewSubscriptionRequestSerializer.Parameters(subscriptionID: subscription.subscriptionID, timeout: _defaultSubscriptionTimeout)
        
        _renewSubscriptionSessionManager.SUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task, responseObject) -> Void in
            guard let response: UPnPEventRenewSubscriptionResponseSerializer.Response = responseObject as? UPnPEventRenewSubscriptionResponseSerializer.Response else {
                if let completion = completion {
                    completion(.failure(createError("Failure serializing event subscribe response")))
                }
                return
            }
            
            let now = Date()
            let expiration = now.addingTimeInterval(TimeInterval(response.timeout))
            
            subscription.update(response.subscriptionID, expiration: expiration)
            
            LogInfo("Successfully renewed subscription with timeout: \(response.timeout/60) mins: \(subscription)")
            
            // read just in case it was removed
            self.add(subscription: subscription, completion: { () -> Void in
                if let completion = completion {
                    completion(Result.success(subscription))
                }
            })
            }, failure: { (task: URLSessionDataTask?, error: NSError) -> Void in
                LogError("Failed to renew subscription: \(subscription)\nerror: \(error)")
                if let completion = completion {
                    completion(.failure(error))
                }
        })
    }
    
    fileprivate func resubscribe(_ subscription: Subscription, completion: ((_ result: Result<AnyObject>) -> Void)? = nil) {
        // remove, just in case resubscription fails
        remove(subscription: subscription)
        
        let failureClosure = { (error: NSError) -> Void in
            subscription.subscriber?.subscriptionDidFail(self)
            
            if let completion = completion {
                completion(.failure(error))
            }
        }
        
        // re-subscribe only if subscriber still exists
        guard subscription.subscriber != nil else {
            failureClosure(createError("Subscriber doesn't exist anymore"))
            return
        }
        
        self.eventCallBackURL({ [unowned self] (eventCallBackURL: URL?) -> Void in
            guard let eventCallBackURL: URL = eventCallBackURL else {
                failureClosure(createError("Event call back URL could not be created"))
                return
            }
            
            let parameters = UPnPEventSubscribeRequestSerializer.Parameters(callBack: eventCallBackURL, timeout: self._defaultSubscriptionTimeout)
            
            self._subscribeSessionManager.SUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task, responseObject) -> Void in
                guard let response: UPnPEventSubscribeResponseSerializer.Response = responseObject as? UPnPEventSubscribeResponseSerializer.Response else {
                    failureClosure(createError("Failure serializing event subscribe response"))
                    return
                }
                
                let now = Date()
                let expiration = now.addingTimeInterval(TimeInterval(response.timeout))
                
                subscription.update(response.subscriptionID, expiration: expiration)
                
                LogInfo("Successfully re-subscribed with timeout: \(response.timeout/60) mins: \(subscription)")
                
                self.add(subscription: subscription, completion: { () -> Void in
                    if let completion = completion {
                        completion(Result.success(subscription))
                    }
                })
                }, failure: { (task: URLSessionDataTask?, error: NSError) -> Void in
                    LogError("Failed to re-subscribe: \(subscription)\nerror: \(error)")
                    
                    failureClosure(error)
            })
        })
    }
    
    fileprivate func subscriptionNeedsRenewal(_ subscription: Subscription) {
        renewSubscription(subscription)
    }
    
    fileprivate func subscriptionDidExpire(_ subscription: Subscription) {
        resubscribe(subscription, completion: {
            if let errorDescription = $0.error?.localizedDescriptionOrNil {
                LogError("\(errorDescription)")
            }
        })
    }
    
    fileprivate func startHTTPServer() -> Bool {
        if _httpServer.safeToStart {
            return _httpServer.start(withPort: _httpServerPort, bonjourName: nil)
        }
        
        return false
    }
    
    fileprivate func stopHTTPServer() -> Bool {
        if _httpServer.safeToStop {
            _httpServer.stop()
            return true
        }
        
        return false
    }
}

internal func ==(lhs: UPnPEventSubscriptionManager.Subscription, rhs: UPnPEventSubscriptionManager.Subscription) -> Bool {
    return lhs.subscriptionID == rhs.subscriptionID
}

extension UPnPEventSubscriptionManager.Subscription: ExtendedPrintable {
    #if os(iOS)
    var className: String { return "Subscription" }
    #elseif os(OSX) // NSObject.className actually exists on OSX! Who knew.
    override var className: String { return "Subscription" }
    #endif
    override var description: String {
        var properties = PropertyPrinter()
        properties.add("subscriptionID", property: subscriptionID)
        properties.add("expiration", property: expiration)
        properties.add("eventURLString", property: eventURLString)
        return properties.description
    }
}

extension AFHTTPSessionManager {
    func SUBSCRIBE(_ URLString: String, parameters: AnyObject, success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)?, failure: ((_ task: URLSessionDataTask?, _ error: NSError) -> Void)?) -> URLSessionDataTask? {
        let dataTask = self.dataTask("SUBSCRIBE", URLString: URLString, parameters: parameters, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    func UNSUBSCRIBE(_ URLString: String, parameters: AnyObject, success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)?, failure: ((_ task: URLSessionDataTask?, _ error: NSError) -> Void)?) -> URLSessionDataTask? {
        let dataTask = self.dataTask("UNSUBSCRIBE", URLString: URLString, parameters: parameters, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    fileprivate func dataTask(_ method: String, URLString: String, parameters: AnyObject, success: ((_ task: URLSessionDataTask, _ responseObject: Any?) -> Void)?, failure: ((_ task: URLSessionDataTask?, _ error: NSError) -> Void)?) -> URLSessionDataTask? {
        let request: URLRequest!
        var serializationError: NSError?
        request = try self.requestSerializer.request(withMethod: method, urlString: URL(string: URLString, relativeTo: self.baseURL)!.absoluteURL.absoluteString, parameters: parameters, error: &serializationError) as URLRequest!
        
        if let serializationError = serializationError {
            if let failure = failure {
                (self.completionQueue != nil ? self.completionQueue : DispatchQueue.main)?.async(execute: { () -> Void in
                    failure(nil, serializationError)
                })
            }
            
            return nil
        }
        
        var dataTask: URLSessionDataTask!
        dataTask = self.dataTask(with: request, completionHandler: { (response, responseObject, error) -> Void in
            if let error = error {
                if let failure = failure {
                    failure(dataTask, error as NSError)
                }
            } else {
                if let success = success {
                    success(dataTask, responseObject)
                }
            }
        })
        
        return dataTask
    }
}

extension GCDWebServer {
    var safeToStart: Bool {
        // prevents a crash where although the http server reports running is false, attempting to start while GCDWebServer->_source4 is not null causes abort() to be called which kills the app. GCDWebServer.serverURL == nil is equivalent to GCDWebServer->_source4 == NULL.
        return !isRunning && serverURL == nil
    }
    
    var safeToStop: Bool {
        // prevents a crash where http server must actually be running to stop it or abort() is called which kills the app.
        return isRunning
    }
}
