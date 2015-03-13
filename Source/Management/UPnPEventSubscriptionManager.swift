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
import CocoaHTTPServer

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
    let eventCallBackPath = "/Event/\(NSUUID().dashlessUUIDString)"
    
    // private
    /// Must be accessed within dispatch_sync() and updated within dispatch_barrier_async()
    private var _subscriptions = [String: Subscription]() /* [eventURLString: Subscription] */
    private let _concurrentSubscriptionQueue = dispatch_queue_create("com.upnatom.upnp-event-subscription-manager.subscription-queue", DISPATCH_QUEUE_CONCURRENT)
    private let _httpServer = HTTPServer()
    private let _httpServerPort = 52808
    private let _subscribeSessionManager = AFHTTPSessionManager()
    private let _renewSubscriptionSessionManager = AFHTTPSessionManager()
    private let _unsubscribeSessionManager = AFHTTPSessionManager()
    private let _defaultSubscriptionTimeout: Int = 300
    private var _eventCallBackURL: NSURL? {
        let wifiInterface = "en0"
        if let address = getIFAddresses()[wifiInterface] {
            var url = NSURLComponents()
            url.scheme = "http"
            url.port = _httpServerPort
            url.path = eventCallBackPath
            url.host = address

            return url.URL!
        }
        
        return nil
    }
    /// Calling this on the main thread is not recommended as it will block until completed, blocking the main thread is a no-no
    private var subscriptions: [String: Subscription] {
        var subscriptions: [String: Subscription]!
        dispatch_sync(_concurrentSubscriptionQueue, { () -> Void in
            // Dictionaries are structures and therefore copied when assigned to a new constant or variable
            subscriptions = self._subscriptions
        })
        return subscriptions
    }
    
    init() {
        _httpServer.setPort(UInt16(_httpServerPort))
        _httpServer.setConnectionClass(UPnPEventHTTPConnection.self)
        
        _subscribeSessionManager.requestSerializer = UPnPEventSubscribeRequestSerializer() as AFHTTPRequestSerializer
        _subscribeSessionManager.responseSerializer = UPnPEventSubscribeResponseSerializer()
        
        _renewSubscriptionSessionManager.requestSerializer = UPnPEventRenewSubscriptionRequestSerializer() as AFHTTPRequestSerializer
        _renewSubscriptionSessionManager.responseSerializer = UPnPEventRenewSubscriptionResponseSerializer()
        
        _unsubscribeSessionManager.requestSerializer = UPnPEventUnsubscribeRequestSerializer() as AFHTTPRequestSerializer
        _unsubscribeSessionManager.responseSerializer = UPnPEventUnsubscribeResponseSerializer()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "applicationDidEnterBackground:",
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "applicationWillEnterForeground:",
            name: UIApplicationWillEnterForegroundNotification,
            object: nil)
    }
    
    /// Subscribers should hold on to a weak reference of the subscription object returned. It's ok to call subscribe for a subscription that already exists, the subscription will simply be looked up and returned.
    func subscribe(subscriber: UPnPEventSubscriber, eventURL: NSURL, completion: ((result: Result<AnyObject>) -> Void)? = nil) {
        let eventURLString: String! = eventURL.absoluteString
        if eventURLString == nil {
            if let completion = completion {
                completion(result: .Failure(createError("Event URL does not exist")))
            }
            return
        }
        
        // check if subscription for event URL already exists
        if let subscription = self.subscriptions[eventURLString] {
            if let completion = completion {
                completion(result: .Success(subscription))
            }
            return
        }
        
        if _eventCallBackURL == nil {
            if let completion = completion {
                completion(result: .Failure(createError("Event call back URL could not be created")))
            }
            return
        }
        
        LogInfo("event callback url: \(_eventCallBackURL!)")
        
        let parameters = UPnPEventSubscribeRequestSerializer.Parameters(callBack: _eventCallBackURL!, timeout: _defaultSubscriptionTimeout)
        
        _subscribeSessionManager.SUBSCRIBE(eventURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            let response: UPnPEventSubscribeResponseSerializer.Response! = responseObject as? UPnPEventSubscribeResponseSerializer.Response
            if response == nil {
                if let completion = completion {
                    completion(result: .Failure(createError("Failure serializing event subscribe response")))
                }
                return
            }
            
            let now = NSDate()
            let expiration = now.dateByAddingTimeInterval(NSTimeInterval(response.timeout))
            
            let subscription = Subscription(subscriptionID: response.subscriptionID, expiration: expiration, subscriber: subscriber, eventURLString: eventURL.absoluteString!, manager: self)
            
            LogInfo("Successfully subscribed with timeout: \(response.timeout/60) mins: \(subscription)")
            
            self.add(subscription: subscription, completion: { () -> Void in
                if let completion = completion {
                    completion(result: .Success(subscription))
                }
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                LogError("Failed to subscribe to event URL: \(eventURL.absoluteString!)\nerror: \(error)")
                if let completion = completion {
                    completion(result: .Failure(error))
                }
        })
    }
    
    func unsubscribe(subscription: Any, completion: ((result: EmptyResult) -> Void)? = nil) {
        let subscription: Subscription! = subscription as? Subscription
        if subscription == nil {
            if let completion = completion {
                completion(result: .Failure(createError("Failure using subscription object passed in")))
            }
            return
        }
        
        let parameters = UPnPEventUnsubscribeRequestSerializer.Parameters(subscriptionID: subscription.subscriptionID)
        
        _unsubscribeSessionManager.UNSUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            LogInfo("Successfully unsubscribed: \(subscription)")
            
            self.remove(subscription: subscription, completion: { () -> Void in
                if let completion = completion {
                    completion(result: .Success)
                }
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                LogError("Failed to unsubscribe: \(subscription)\nerror: \(error)")
                self.remove(subscription: subscription, completion: { () -> Void in
                    if let completion = completion {
                        completion(result: .Failure(error))
                    }
                })
        })
    }
    
    func handleIncomingEvent(#subscriptionID: String, eventData: NSData) {
        if let subscription: Subscription = (subscriptions.values.array as NSArray).firstUsingPredicate(NSPredicate(format: "subscriptionID = %@", subscriptionID)!) {
            subscription.subscriber?.handleEvent(self, eventXML: eventData)
        }
    }
    
    @objc private func applicationDidEnterBackground(notification: NSNotification) {
        if _httpServer.isRunning() {
            _httpServer.stop()
        }
        
        subscriptions { [unowned self] (subscriptions: [String: Subscription]) -> Void in
            // invalidate all timers before being backgrounded as the will be trashed upon foregrounding anyways
            for (eventURL, subscription) in subscriptions {
                subscription.invalidate()
            }
        }
    }
    
    @objc private func applicationWillEnterForeground(notification: NSNotification) {
        subscriptions { [unowned self] (subscriptions: [String: Subscription]) -> Void in
            // unsubscribe and re-subscribe for all event subscriptions
            for (eventURL, subscription) in subscriptions {
                self.unsubscribe(subscription, completion: { (result) -> Void in
                    self.resubscribe(subscription)
                })
            }            
        }
    }
    
    private func add(#subscription: Subscription, completion: (() -> Void)? = nil) {
        let originalQueue = NSOperationQueue.currentQueue()
        dispatch_barrier_async(self._concurrentSubscriptionQueue, { () -> Void in
            self._subscriptions[subscription.eventURLString] = subscription
            self.startStopHTTPServerIfNeeded(self._subscriptions)
            
            // kick the completion back onto original queue
            if let completion = completion {
                originalQueue?.addOperationWithBlock(completion)
            }
        })
    }
    
    private func remove(#subscription: Subscription, completion: (() -> Void)? = nil) {
        let originalQueue = NSOperationQueue.currentQueue()
        dispatch_barrier_async(self._concurrentSubscriptionQueue, { () -> Void in
            self._subscriptions.removeValueForKey(subscription.eventURLString)?.invalidate()
            self.startStopHTTPServerIfNeeded(self._subscriptions)
            
            // kick the completion back onto original queue
            if let completion = completion {
                originalQueue?.addOperationWithBlock(completion)
            }
        })
    }
    
    /// Safe to call from main thread
    private func subscriptions(closure: (subscriptions: [String: Subscription]) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let subscriptions = self.subscriptions
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                closure(subscriptions: subscriptions)
            })
        })
    }
    
    private func startStopHTTPServerIfNeeded(subscriptions: [String: Subscription]) {
        let httpServer = self._httpServer
        if subscriptions.count == 0 {
            httpServer.stop()
        }
        else if subscriptions.count > 0 && !httpServer.isRunning() {
            var error: NSError?
            if !httpServer.start(&error) {
                let toAppend = error != nil && error?.localizedDescriptionOrNil != nil ? ": \(error!.localizedDescription)" : ""
                LogError("Error starting HTTP server" + toAppend)
            }
        }
    }
    
    private func renewSubscription(subscription: Subscription, completion: ((result: Result<AnyObject>) -> Void)? = nil) {
        if subscription.subscriber == nil {
            if let completion = completion {
                completion(result: .Failure(createError("Subscriber doesn't exist anymore")))
            }
            return
        }
        
        let parameters = UPnPEventRenewSubscriptionRequestSerializer.Parameters(subscriptionID: subscription.subscriptionID, timeout: _defaultSubscriptionTimeout)
        
        _renewSubscriptionSessionManager.SUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            let response: UPnPEventRenewSubscriptionResponseSerializer.Response! = responseObject as? UPnPEventRenewSubscriptionResponseSerializer.Response
            if response == nil {
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
                    completion(result: .Success(subscription))
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
        
        // re-subscribe only if subscriber still exists
        if subscription.subscriber == nil {
            if let completion = completion {
                completion(result: .Failure(createError("Subscriber doesn't exist anymore")))
            }
            return
        }
        
        let parameters = UPnPEventSubscribeRequestSerializer.Parameters(callBack: _eventCallBackURL!, timeout: _defaultSubscriptionTimeout)
        
        _subscribeSessionManager.SUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            let response: UPnPEventSubscribeResponseSerializer.Response! = responseObject as? UPnPEventSubscribeResponseSerializer.Response
            if response == nil {
                if let completion = completion {
                    completion(result: .Failure(createError("Failure serializing event subscribe response")))
                }
                return
            }
            
            let now = NSDate()
            let expiration = now.dateByAddingTimeInterval(NSTimeInterval(response.timeout))
            
            subscription.update(response.subscriptionID, expiration: expiration)
            
            LogInfo("Successfully re-subscribed with timeout: \(response.timeout/60) mins: \(subscription)")
            
            self.add(subscription: subscription, completion: { () -> Void in
                if let completion = completion {
                    completion(result: .Success(subscription))
                }
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                LogError("Failed to re-subscribe: \(subscription)\nerror: \(error)")
                
                subscription.subscriber?.subscriptionDidFail(self)
                
                if let completion = completion {
                    completion(result: .Failure(error))
                }
        })
    }
    
    private func subscriptionNeedsRenewal(subscription: Subscription) {
        renewSubscription(subscription)
    }
    
    private func subscriptionDidExpire(subscription: Subscription) {
        resubscribe(subscription)
    }
}

extension UPnPEventSubscriptionManager.Subscription: Equatable { }

internal func ==(lhs: UPnPEventSubscriptionManager.Subscription, rhs: UPnPEventSubscriptionManager.Subscription) -> Bool {
    return lhs.subscriptionID == rhs.subscriptionID
}

extension UPnPEventSubscriptionManager.Subscription: ExtendedPrintable {
    var className: String { return "Subscription" }
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
        var serializationError: NSError?
        let request = self.requestSerializer.requestWithMethod(method, URLString: NSURL(string: URLString, relativeToURL: self.baseURL)?.absoluteString, parameters: parameters, error: &serializationError)
        if let serializationError = serializationError {
            if let failure = failure {
                dispatch_async(self.completionQueue != nil ? self.completionQueue : dispatch_get_main_queue(), { () -> Void in
                    failure(task: nil, error: serializationError)
                })
            }
            
            return nil
        }
        
        var dataTask: NSURLSessionDataTask!
        dataTask = self.dataTaskWithRequest(request, completionHandler: { (response: NSURLResponse!, responseObject: AnyObject!, error: NSError!) -> Void in
            if let error = error {
                if let failure = failure {
                    failure(task: dataTask, error: error)
                }
            }
            else {
                if let success = success {
                    success(task: dataTask, responseObject: responseObject)
                }
            }
        })
        
        return dataTask
    }
}
