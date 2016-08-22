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
    func handleEvent(eventSubscriptionManager: UPnPEventSubscriptionManager, eventXML: NSData)
    func subscriptionDidFail(eventSubscriptionManager: UPnPEventSubscriptionManager)
}

class UPnPEventSubscriptionManager {
    // Subclasses NSObject in order to filter collections of this class using NSPredicate
    class Subscription: NSObject {
        private(set) var subscriptionID: String
        private(set) var expiration: NSDate
        weak var subscriber: UPnPEventSubscriber?
        let eventURLString: String
        private unowned let _manager: UPnPEventSubscriptionManager
        private var _renewDate: NSDate {
            return expiration.dateByAddingTimeInterval(-30) // attempt renewal 30 seconds before expiration
        }
        private var _renewWarningTimer: NSTimer?
        private var _expirationTimer: NSTimer?
        
        init(subscriptionID: String, expiration: NSDate, subscriber: UPnPEventSubscriber, eventURLString: String, manager: UPnPEventSubscriptionManager) {
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
        
        func update(subscriptionID: String, expiration: NSDate) {
            self.invalidate()
            
            self.subscriptionID = subscriptionID
            self.expiration = expiration
            updateTimers()
        }
        
        private func updateTimers() {
            let renewDate = _renewDate
            let expiration = self.expiration
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self._renewWarningTimer = NSTimer.scheduledTimerWithTimeInterval(renewDate.timeIntervalSinceNow, repeats: false, closure: { [weak self] () -> Void in
                    if let strongSelf = self {
                        strongSelf._manager.subscriptionNeedsRenewal(strongSelf)
                    }
                })
                
                self._expirationTimer = NSTimer.scheduledTimerWithTimeInterval(expiration.timeIntervalSinceNow, repeats: false, closure: { [weak self] () -> Void in
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
    private var _subscriptions = [String: Subscription]() /* [eventURLString: Subscription] */
    private let _concurrentSubscriptionQueue = dispatch_queue_create("com.upnatom.upnp-event-subscription-manager.subscription-queue", DISPATCH_QUEUE_CONCURRENT)
    /// Must be accessed within the subscription manager's concurrent queue
    private var _httpServer: GCDWebServer! // TODO: Should ideally be a constant, non-optional, see Github issue #10
    private let _httpServerPort: UInt = 52808
    private let _subscribeSessionManager = AFHTTPSessionManager()
    private let _renewSubscriptionSessionManager = AFHTTPSessionManager()
    private let _unsubscribeSessionManager = AFHTTPSessionManager()
    private let _defaultSubscriptionTimeout: Int = 1800
    private let _eventCallBackPath = "/Event/\(NSUUID().dashlessUUIDString)"
    
    init() {
        _subscribeSessionManager.requestSerializer = UPnPEventSubscribeRequestSerializer()
        _subscribeSessionManager.responseSerializer = UPnPEventSubscribeResponseSerializer()
        
        _renewSubscriptionSessionManager.requestSerializer = UPnPEventRenewSubscriptionRequestSerializer()
        _renewSubscriptionSessionManager.responseSerializer = UPnPEventRenewSubscriptionResponseSerializer()
        
        _unsubscribeSessionManager.requestSerializer = UPnPEventUnsubscribeRequestSerializer()
        _unsubscribeSessionManager.responseSerializer = UPnPEventUnsubscribeResponseSerializer()
        
        #if os(iOS)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        #endif
        
        /// GCDWebServer must be initialized on the main thread. In order to guarantee this, it's initialization is dispatched on the main queue. To prevent critical sections from accessing it before it is initialized, the dispatch is synchronized within a dispatch barrier to the subscription manager's critical section queue.
        dispatch_barrier_async(_concurrentSubscriptionQueue, { () -> Void in
            dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                self._httpServer = GCDWebServer()
                
                GCDWebServer.setLogLevel(Int32(3))
                
                self._httpServer.addHandlerForMethod("NOTIFY", path: self._eventCallBackPath, requestClass: GCDWebServerDataRequest.self) { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
                    if let dataRequest = request as? GCDWebServerDataRequest,
                        headers = dataRequest.headers as? [String: AnyObject],
                        sid = headers["SID"] as? String,
                        data = dataRequest.data {
                            LogVerbose("NOTIFY request: Final body with size: \(data.length)\nAll headers: \(headers)")
                            self.handleIncomingEvent(subscriptionID: sid, eventData: data)
                    }
                    
                    return GCDWebServerResponse()
                }
            })
        })
    }
    
    /// Subscribers should hold on to a weak reference of the subscription object returned. It's ok to call subscribe for a subscription that already exists, the subscription will simply be looked up and returned.
    func subscribe(subscriber: UPnPEventSubscriber, eventURL: NSURL, completion: ((result: Result<AnyObject>) -> Void)? = nil) {
        let failureClosure = { (error: NSError) -> Void in
            if let completion = completion {
                completion(result: .Failure(error))
            }
        }
        
        guard let eventURLString: String! = eventURL.absoluteString else {
            failureClosure(createError("Event URL does not exist"))
            return
        }
        
        // check if subscription for event URL already exists
        subscriptions { [unowned self] (subscriptions: [String: Subscription]) -> Void in
            if let subscription = subscriptions[eventURLString] {
                if let completion = completion {
                    completion(result: Result.Success(subscription))
                }
                return
            }
            
            self.eventCallBackURL({ [unowned self] (eventCallBackURL: NSURL?) -> Void in
                guard let eventCallBackURL: NSURL = eventCallBackURL else {
                    failureClosure(createError("Event call back URL could not be created"))
                    return
                }
                
                LogInfo("event callback url: \(eventCallBackURL)")
                
                let parameters = UPnPEventSubscribeRequestSerializer.Parameters(callBack: eventCallBackURL, timeout: self._defaultSubscriptionTimeout)
                
                self._subscribeSessionManager.SUBSCRIBE(eventURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    guard let response: UPnPEventSubscribeResponseSerializer.Response = responseObject as? UPnPEventSubscribeResponseSerializer.Response else {
                        failureClosure(createError("Failure serializing event subscribe response"))
                        return
                    }
                    
                    let now = NSDate()
                    let expiration = now.dateByAddingTimeInterval(NSTimeInterval(response.timeout))
                    
                    let subscription = Subscription(subscriptionID: response.subscriptionID, expiration: expiration, subscriber: subscriber, eventURLString: eventURL.absoluteString, manager: self)
                    
                    LogInfo("Successfully subscribed with timeout: \(response.timeout/60) mins: \(subscription)")
                    
                    self.add(subscription: subscription, completion: { () -> Void in
                        if let completion = completion {
                            completion(result: Result.Success(subscription))
                        }
                    })
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        LogError("Failed to subscribe to event URL: \(eventURL.absoluteString)\nerror: \(error)")
                        failureClosure(error)
                })
            })
        }
    }
    
    func unsubscribe(subscription: AnyObject, completion: ((result: EmptyResult) -> Void)? = nil) {
        guard let subscription: Subscription = subscription as? Subscription else {
            if let completion = completion {
                completion(result: .Failure(createError("Failure using subscription object passed in")))
            }
            return
        }
        
        // remove local version of subscription immediately to prevent any race conditions
        self.remove(subscription: subscription, completion: { [unowned self] () -> Void in
            let parameters = UPnPEventUnsubscribeRequestSerializer.Parameters(subscriptionID: subscription.subscriptionID)
            
            self._unsubscribeSessionManager.UNSUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                LogInfo("Successfully unsubscribed: \(subscription)")
                if let completion = completion {
                    completion(result: .Success)
                }
                
                }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                    LogError("Failed to unsubscribe: \(subscription)\nerror: \(error)")
                    if let completion = completion {
                        completion(result: .Failure(error))
                    }
            })
        })
    }
    
    private func handleIncomingEvent(subscriptionID subscriptionID: String, eventData: NSData) {
        subscriptions { (subscriptions: [String: Subscription]) -> Void in
            if let subscription: Subscription = (Array(subscriptions.values) as NSArray).firstUsingPredicate(NSPredicate(format: "subscriptionID = %@", subscriptionID)) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    subscription.subscriber?.handleEvent(self, eventXML: eventData)
                    return
                })
            }
        }
    }
    
    @objc private func applicationDidEnterBackground(notification: NSNotification) {
        // GCDWebServer handles stopping and restarting itself as appropriate during application life cycle events. Invalidating the timers is all that's necessary here :)
        
        subscriptions { (subscriptions: [String: Subscription]) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // invalidate all timers before being backgrounded as the will be trashed upon foregrounding anyways
                for (_, subscription) in subscriptions {
                    subscription.invalidate()
                }
            })
        }
    }
    
    @objc private func applicationWillEnterForeground(notification: NSNotification) {
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
    
    private func add(subscription subscription: Subscription, completion: (() -> Void)? = nil) {
        dispatch_barrier_async(self._concurrentSubscriptionQueue, { () -> Void in
            self._subscriptions[subscription.eventURLString] = subscription
            self.startStopHTTPServerIfNeeded(self._subscriptions.count)
            
            if let completion = completion {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    completion()
                })
            }
        })
    }
    
    private func remove(subscription subscription: Subscription, completion: (() -> Void)? = nil) {
        dispatch_barrier_async(self._concurrentSubscriptionQueue, { () -> Void in
            self._subscriptions.removeValueForKey(subscription.eventURLString)?.invalidate()
            self.startStopHTTPServerIfNeeded(self._subscriptions.count)
            
            if let completion = completion {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    completion()
                })
            }
        })
    }
    
    private func eventCallBackURL(closure: (eventCallBackURL: NSURL?) -> Void) {
        // only reading subscriptions, so distpach_async is appropriate to allow for concurrent reads
        dispatch_async(self._concurrentSubscriptionQueue, { () -> Void in
            // needs to be running in order to get server url for the subscription message
            let httpServer = self._httpServer
            var serverURL: NSURL? = httpServer.serverURL
            
            // most likely nil if the http server is stopped
            if serverURL == nil && !httpServer.running {
                // Start http server
                if self.startHTTPServer() {
                    // Grab server url
                    serverURL = httpServer.serverURL
                    
                    // Stop http server if it's not needed further
                    self.startStopHTTPServerIfNeeded(self._subscriptions.count)
                } else {
                    LogError("Error starting HTTP server")
                }
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                serverURL != nil ? closure(eventCallBackURL: NSURL(string: self._eventCallBackPath, relativeToURL: serverURL)!) : closure(eventCallBackURL: nil)
            })
        })
    }
    
    /// Safe to call from any queue and closure is called on callback queue
    private func subscriptions(closure: (subscriptions: [String: Subscription]) -> Void) {
        // only reading subscriptions, so distpach_async is appropriate to allow for concurrent reads
        dispatch_async(self._concurrentSubscriptionQueue, { () -> Void in
            let subscriptions = self._subscriptions
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                closure(subscriptions: subscriptions)
            })
        })
    }
    
    /// Must be called with the most up to date knowledge of the subscription count so should be called withing the subscription queue.
    // TODO: consider putting entire method inside a dispatch_barrier_async to subscription queue
    private func startStopHTTPServerIfNeeded(subscriptionCount: Int) {
        let httpServer = self._httpServer
        if subscriptionCount == 0 && httpServer.running {
            if !stopHTTPServer() {
                LogError("Error stopping HTTP server")
            }
        } else if subscriptionCount > 0 && !httpServer.running {
            if !startHTTPServer() {
                LogError("Error starting HTTP server")
            }
        }
    }
    
    private func renewSubscription(subscription: Subscription, completion: ((result: Result<AnyObject>) -> Void)? = nil) {
        guard subscription.subscriber != nil else {
            if let completion = completion {
                completion(result: .Failure(createError("Subscriber doesn't exist anymore")))
            }
            return
        }
        
        let parameters = UPnPEventRenewSubscriptionRequestSerializer.Parameters(subscriptionID: subscription.subscriptionID, timeout: _defaultSubscriptionTimeout)
        
        _renewSubscriptionSessionManager.SUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            guard let response: UPnPEventRenewSubscriptionResponseSerializer.Response = responseObject as? UPnPEventRenewSubscriptionResponseSerializer.Response else {
                if let completion = completion {
                    completion(result: .Failure(createError("Failure serializing event subscribe response")))
                }
                return
            }
            
            let now = NSDate()
            let expiration = now.dateByAddingTimeInterval(NSTimeInterval(response.timeout))
            
            subscription.update(response.subscriptionID, expiration: expiration)
            
            LogInfo("Successfully renewed subscription with timeout: \(response.timeout/60) mins: \(subscription)")
            
            // read just in case it was removed
            self.add(subscription: subscription, completion: { () -> Void in
                if let completion = completion {
                    completion(result: Result.Success(subscription))
                }
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                LogError("Failed to renew subscription: \(subscription)\nerror: \(error)")
                if let completion = completion {
                    completion(result: .Failure(error))
                }
        })
    }
    
    private func resubscribe(subscription: Subscription, completion: ((result: Result<AnyObject>) -> Void)? = nil) {
        // remove, just in case resubscription fails
        remove(subscription: subscription)
        
        let failureClosure = { (error: NSError) -> Void in
            subscription.subscriber?.subscriptionDidFail(self)
            
            if let completion = completion {
                completion(result: .Failure(error))
            }
        }
        
        // re-subscribe only if subscriber still exists
        guard subscription.subscriber != nil else {
            failureClosure(createError("Subscriber doesn't exist anymore"))
            return
        }
        
        self.eventCallBackURL({ [unowned self] (eventCallBackURL: NSURL?) -> Void in
            guard let eventCallBackURL: NSURL = eventCallBackURL else {
                failureClosure(createError("Event call back URL could not be created"))
                return
            }
            
            let parameters = UPnPEventSubscribeRequestSerializer.Parameters(callBack: eventCallBackURL, timeout: self._defaultSubscriptionTimeout)
            
            self._subscribeSessionManager.SUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                guard let response: UPnPEventSubscribeResponseSerializer.Response = responseObject as? UPnPEventSubscribeResponseSerializer.Response else {
                    failureClosure(createError("Failure serializing event subscribe response"))
                    return
                }
                
                let now = NSDate()
                let expiration = now.dateByAddingTimeInterval(NSTimeInterval(response.timeout))
                
                subscription.update(response.subscriptionID, expiration: expiration)
                
                LogInfo("Successfully re-subscribed with timeout: \(response.timeout/60) mins: \(subscription)")
                
                self.add(subscription: subscription, completion: { () -> Void in
                    if let completion = completion {
                        completion(result: Result.Success(subscription))
                    }
                })
                }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                    LogError("Failed to re-subscribe: \(subscription)\nerror: \(error)")
                    
                    failureClosure(error)
            })
        })
    }
    
    private func subscriptionNeedsRenewal(subscription: Subscription) {
        renewSubscription(subscription)
    }
    
    private func subscriptionDidExpire(subscription: Subscription) {
        resubscribe(subscription, completion: {
            if let errorDescription = $0.error?.localizedDescriptionOrNil {
                LogError("\(errorDescription)")
            }
        })
    }
    
    private func startHTTPServer() -> Bool {
        if _httpServer.safeToStart {
            return _httpServer.startWithPort(_httpServerPort, bonjourName: nil)
        }
        
        return false
    }
    
    private func stopHTTPServer() -> Bool {
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
    func SUBSCRIBE(URLString: String, parameters: AnyObject, success: ((task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void)?, failure: ((task: NSURLSessionDataTask?, error: NSError) -> Void)?) -> NSURLSessionDataTask? {
        let dataTask = self.dataTask("SUBSCRIBE", URLString: URLString, parameters: parameters, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    func UNSUBSCRIBE(URLString: String, parameters: AnyObject, success: ((task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void)?, failure: ((task: NSURLSessionDataTask?, error: NSError) -> Void)?) -> NSURLSessionDataTask? {
        let dataTask = self.dataTask("UNSUBSCRIBE", URLString: URLString, parameters: parameters, success: success, failure: failure)
        dataTask?.resume()
        return dataTask
    }
    
    private func dataTask(method: String, URLString: String, parameters: AnyObject, success: ((task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void)?, failure: ((task: NSURLSessionDataTask?, error: NSError) -> Void)?) -> NSURLSessionDataTask? {
        let request: NSURLRequest!
        var serializationError: NSError?
        request = try self.requestSerializer.requestWithMethod(method, URLString: NSURL(string: URLString, relativeToURL: self.baseURL)!.absoluteString, parameters: parameters, error: &serializationError)
        
        if let serializationError = serializationError {
            if let failure = failure {
                dispatch_async(self.completionQueue != nil ? self.completionQueue : dispatch_get_main_queue(), { () -> Void in
                    failure(task: nil, error: serializationError)
                })
            }
            
            return nil
        }
        
        var dataTask: NSURLSessionDataTask!
        dataTask = self.dataTaskWithRequest(request, completionHandler: { (response: NSURLResponse, responseObject: AnyObject?, error: NSError?) -> Void in
            if let error = error {
                if let failure = failure {
                    failure(task: dataTask, error: error)
                }
            } else {
                if let success = success {
                    success(task: dataTask, responseObject: responseObject)
                }
            }
        })
        
        return dataTask
    }
}

extension GCDWebServer {
    var safeToStart: Bool {
        // prevents a crash where although the http server reports running is false, attempting to start while GCDWebServer->_source4 is not null causes abort() to be called which kills the app. GCDWebServer.serverURL == nil is equivalent to GCDWebServer->_source4 == NULL.
        return !running && serverURL == nil
    }
    
    var safeToStop: Bool {
        // prevents a crash where http server must actually be running to stop it or abort() is called which kills the app.
        return running
    }
}
