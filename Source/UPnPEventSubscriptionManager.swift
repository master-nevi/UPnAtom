//
//  UPnPEventSubscriptionManager.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/22/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

protocol UPnPEventSubscriber {
    func handleEvent(eventSubscriptionManager: UPnPEventSubscriptionManager, eventInfo: [String: String])
}

internal class UPnPEventSubscriptionManager {
    // Subclasses NSObject in order to filter collections of this class using NSPredicate
    private class Subscription: NSObject {
        let subscriptionID: String
        let expiration: NSDate
        let subscriber: UPnPEventSubscriber
        let eventURLString: String
        
        init(subscriptionID: String, expiration: NSDate, subscriber: UPnPEventSubscriber, eventURLString: String) {
            self.subscriptionID = subscriptionID
            self.expiration = expiration
            self.subscriber = subscriber
            self.eventURLString = eventURLString
        }
    }
    
    // public
    let eventCallBackPath = "/Event"
    
    // private
    private var _subscriptions = [String: Subscription]()
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
    
    func subscribe(subscriber: UPnPEventSubscriber, eventURL: NSURL, completion: (subscription: Result<Any>) -> Void) {
        let hasSubscriptionForEventURL: Bool = (_subscriptions.values.array as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "eventURLString = %@", eventURL.absoluteString!)!).count > 0
        if hasSubscriptionForEventURL {
            completion(subscription: .Failure(createError("Subscription for event URL exists")))
            return
        }
        
        if _eventCallBackURL == nil {
            completion(subscription: .Failure(createError("Event call back URL could not be created")))
            return
        }
        
        let parameters = UPnPEventSubscribeRequestSerializer.Parameters(callBack: _eventCallBackURL!, timeout: _defaultSubscriptionTimeout)
        
        _subscribeSessionManager.SUBSCRIBE(eventURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            let response: UPnPEventSubscribeResponseSerializer.Response! = responseObject as? UPnPEventSubscribeResponseSerializer.Response
            if response == nil {
                completion(subscription: .Failure(createError("Failure serializing event subscribe response")))
                return
            }
            
            let now = NSDate()
            let expiration = now.dateByAddingTimeInterval(NSTimeInterval(response.timeout))
            
            let subscription = Subscription(subscriptionID: response.subscriptionID, expiration: expiration, subscriber: subscriber, eventURLString: eventURL.absoluteString!)
            
            dispatch_barrier_async(self._concurrentSubscriptionQueue, { () -> Void in
                self._subscriptions[subscription.subscriptionID] = subscription
                self.startStopHTTPServerIfNeeded()
                completion(subscription: .Success(subscription))
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
            completion(subscription: .Failure(error))
        })
    }
    
    func unsubscribe(subscription: Any, completion: (result: EmptyResult) -> Void ) {
        let subscription: Subscription! = subscription as? Subscription
        if subscription == nil {
            completion(result: .Failure(createError("Failure using subscription object passed in")))
            return
        }
        
        let parameters = UPnPEventUnsubscribeRequestSerializer.Parameters(subscriptionID: subscription.subscriptionID)
        
        _unsubscribeSessionManager.UNSUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            dispatch_barrier_async(self._concurrentSubscriptionQueue, { () -> Void in
                self._subscriptions.removeValueForKey(subscription.subscriptionID)
                self.startStopHTTPServerIfNeeded()
                completion(result: .Success)
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
            completion(result: .Failure(error))
        })
    }
    
    /// TODO: parse event data
    internal func handleIncomingEvent(#subscriptionID: String, eventData: NSData) {
        if let subscription = (_subscriptions.values.array as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "subscriptionID = %@", subscriptionID)!).first as? Subscription {
            subscription.subscriber.handleEvent(self, eventInfo: [:])
        }
    }
    
    @objc private func applicationDidEnterBackground(notification: NSNotification){
        if _httpServer.isRunning() {
            _httpServer.stop()
        }
        
        /// TODO: unsubscribe from all events and backup subscriptions
    }
    
    @objc private func applicationWillEnterForeground(notification: NSNotification){
        startStopHTTPServerIfNeeded()
        
        /// TODO: resubscribe to all backedup subscriptions
    }
    
    private func startStopHTTPServerIfNeeded() {
        if _subscriptions.count == 0 {
            _httpServer.stop()
        }
        else if _subscriptions.count > 0 && !_httpServer.isRunning() {
            var error: NSError?
            if !_httpServer.start(&error) {
                error != nil ? println("Error starting HTTP server: \(error!.localizedDescription)") : println("Error starting HTTP server")
            }
        }
    }
    
    private func renewSubscription(subscription: Subscription, completion: (subscription: Result<Any>) -> Void) {
        let parameters = UPnPEventRenewSubscriptionRequestSerializer.Parameters(subscriptionID: subscription.subscriptionID, timeout: _defaultSubscriptionTimeout)
        
        _renewSubscriptionSessionManager.SUBSCRIBE(subscription.eventURLString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            let response: UPnPEventRenewSubscriptionResponseSerializer.Response! = responseObject as? UPnPEventRenewSubscriptionResponseSerializer.Response
            if response == nil {
                completion(subscription: .Failure(createError("Failure serializing event subscribe response")))
                return
            }
            
            let now = NSDate()
            let expiration = now.dateByAddingTimeInterval(NSTimeInterval(response.timeout))
            
            let subscription = Subscription(subscriptionID: response.subscriptionID, expiration: expiration, subscriber: subscription.subscriber, eventURLString: subscription.eventURLString)
            
            dispatch_barrier_async(self._concurrentSubscriptionQueue, { () -> Void in
                self._subscriptions[subscription.subscriptionID] = subscription
                self.startStopHTTPServerIfNeeded()
                completion(subscription: .Success(subscription))
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                completion(subscription: .Failure(error))
        })
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
                    success(task: dataTask, responseObject: responseObject)
                }
            }
        })
        
        return dataTask
    }
}
