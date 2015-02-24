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
    func handleEvent(eventSubscriptionManager: UPnPEventSubscriptionManager, eventInfo: [String: String])
}

internal class UPnPEventSubscriptionManager {
    // Subclasses NSObject in order to filter collections of this class using NSPredicate
    private class Subscription: NSObject {
        let subscriptionID: String
        let expiration: NSDate
        weak var subscriber: UPnPEventSubscriber?
        let eventURLString: String
        private unowned let _manager: UPnPEventSubscriptionManager
        private let _renewDate: NSDate
        private var _renewWarningTimer: NSTimer?
        private var _expirationTimer: NSTimer?
        
        init(subscriptionID: String, expiration: NSDate, subscriber: UPnPEventSubscriber, eventURLString: String, manager: UPnPEventSubscriptionManager) {
            self.subscriptionID = subscriptionID
            self.expiration = expiration
            self.subscriber = subscriber
            self.eventURLString = eventURLString
            _manager = manager
            let renewDate = expiration.dateByAddingTimeInterval(-30) // attempt renewal 30 seconds before expiration
            _renewDate = renewDate
            
            super.init()
            
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
        
        func invalidate() {
            _renewWarningTimer?.invalidate()
            _expirationTimer?.invalidate()
        }
    }
    
    // public
    let eventCallBackPath = "/Event"
    
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
    private var _backupSubscriptions = [Subscription]()
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
    
    func subscribe(subscriber: UPnPEventSubscriber, eventURL: NSURL, completion: ((result: Result<Any>) -> Void)? = nil) {
        let eventURLString: String! = eventURL.absoluteString
        if eventURLString == nil {
            if let completion = completion {
                completion(result: .Failure(createError("Event URL does not exist")))
            }
            return
        }
        
        if self.subscriptions()[eventURLString] != nil {
            if let completion = completion {
                completion(result: .Failure(createError("Subscription for event URL exists")))
            }
            return
        }
        
        if _eventCallBackURL == nil {
            if let completion = completion {
                completion(result: .Failure(createError("Event call back URL could not be created")))
            }
            return
        }
        
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
            
            self.add(subscription: subscription, completion: { () -> Void in
                if let completion = completion {
                    completion(result: .Success(subscription))
                }
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
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
            self.remove(subscription: subscription, completion: { () -> Void in
                if let completion = completion {
                    completion(result: .Success)
                }
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                self.remove(subscription: subscription, completion: { () -> Void in
                    if let completion = completion {
                        completion(result: .Failure(error))
                    }
                })
        })
    }
    
    /// TODO: parse event data
    internal func handleIncomingEvent(#subscriptionID: String, eventData: NSData) {
        if let subscription = (subscriptions().values.array as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "subscriptionID = %@", subscriptionID)!).first as? Subscription {
            subscription.subscriber?.handleEvent(self, eventInfo: [:])
        }
    }
    
    @objc private func applicationDidEnterBackground(notification: NSNotification){
        if _httpServer.isRunning() {
            _httpServer.stop()
        }
        
        /// backup subscriptions and unsubscribe from all events
        let subscriptions = self.subscriptions().values.array
        _backupSubscriptions = subscriptions
        
        for subscription in subscriptions {
            unsubscribe(subscription)
        }
    }
    
    @objc private func applicationWillEnterForeground(notification: NSNotification){
        startStopHTTPServerIfNeeded()
        
        /// resubscribe to all backed up subscriptions
        let subscriptions = _backupSubscriptions
        _backupSubscriptions.removeAll(keepCapacity: false)
        
        for subscription in subscriptions {
            if let subscriber = subscription.subscriber {
                subscribe(subscriber, eventURL: NSURL(string: subscription.eventURLString)!)
            }
        }
    }
    
    private func add(#subscription: Subscription, completion: (() -> Void)? = nil) {
        let originalQueue = NSOperationQueue.currentQueue()
        dispatch_barrier_async(self._concurrentSubscriptionQueue, { () -> Void in
            if let previousSubscription = self._subscriptions[subscription.eventURLString] {
                previousSubscription.invalidate()
            }
            
            self._subscriptions[subscription.eventURLString] = subscription
            self.startStopHTTPServerIfNeeded()
            
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
            self.startStopHTTPServerIfNeeded()
            
            // kick the completion back onto original queue
            if let completion = completion {
                originalQueue?.addOperationWithBlock(completion)
            }
        })
    }
    
    private func subscriptions() -> [String: Subscription] {
        var subscriptions: [String: Subscription]!
        dispatch_sync(_concurrentSubscriptionQueue, { () -> Void in
            // Dictionaries are structures and therefore copied when assigned to a new constant or variable
            subscriptions = self._subscriptions
        })
        return subscriptions
    }
    
    private func startStopHTTPServerIfNeeded() {
        let subscriptions = self.subscriptions()
        
        if subscriptions.count == 0 {
            _httpServer.stop()
        }
        else if subscriptions.count > 0 && !_httpServer.isRunning() {
            var error: NSError?
            if !_httpServer.start(&error) {
                error != nil ? println("Error starting HTTP server: \(error!.localizedDescription)") : println("Error starting HTTP server")
            }
        }
    }
    
    private func renewSubscription(subscription: Subscription, completion: ((result: Result<Any>) -> Void)? = nil) {
        let subscriber: UPnPEventSubscriber! = subscription.subscriber
        if subscriber == nil {
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
            
            let subscription = Subscription(subscriptionID: response.subscriptionID, expiration: expiration, subscriber: subscriber, eventURLString: subscription.eventURLString, manager: self)
            
            self.add(subscription: subscription, completion: { () -> Void in
                if let completion = completion {
                    completion(result: .Success(subscription))
                }
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                if let completion = completion {
                    completion(result: .Failure(error))
                }
        })
    }
    
    private func subscriptionNeedsRenewal(subscription: Subscription) {
        self.renewSubscription(subscription)
    }
    
    private func subscriptionDidExpire(subscription: Subscription) {
        // if subscriber still exists then re-subscribe, else remove subscription
        if let subscriber = subscription.subscriber {
            self.subscribe(subscriber, eventURL: NSURL(string: subscription.eventURLString)!, completion: { [unowned self] (result: Result<Any>) -> Void in
                if result.failed {
                    self.remove(subscription: subscription)
                }
            })
        }
        else {
            self.remove(subscription: subscription)
        }
    }
}

extension UPnPEventSubscriptionManager.Subscription: Equatable { }

private func ==(lhs: UPnPEventSubscriptionManager.Subscription, rhs: UPnPEventSubscriptionManager.Subscription) -> Bool {
    return lhs.subscriptionID == rhs.subscriptionID
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
                    /// TODO: check if dataTask can be referenced this way
                    success(task: dataTask, responseObject: responseObject)
                }
            }
        })
        
        return dataTask
    }
}
