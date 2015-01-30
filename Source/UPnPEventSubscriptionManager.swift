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
    
    // private
    private var _subscriptions = [String: Subscription]()
    private let _concurrentSubscriptionQueue = dispatch_queue_create("com.upnatom.upnp-event-subscription-manager.subscription-queue", DISPATCH_QUEUE_CONCURRENT)
    private let _httpServer = HTTPServer()
    private let _httpServerPort: UInt16 = 52808
    
    init() {
        _httpServer.setPort(_httpServerPort)
        _httpServer.setConnectionClass(UPnPEventHTTPConnection.self)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "applicationDidEnterBackground:",
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "applicationWillEnterForeground:",
            name: UIApplicationWillEnterForegroundNotification,
            object: nil)
    }
    
    func subscribe(subscriber: UPnPEventSubscriber, eventURL: NSURL, completion: (subscription: Result<AnyObject>) -> Void) {
        let hasSubscriptionForEventURL: Bool = (_subscriptions.values.array as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "eventURLString = %@", eventURL.absoluteString!)!).count > 0
        if hasSubscriptionForEventURL {
            completion(subscription: .Failure(createError("Subscription for event URL exists")))
            return
        }
    }
    
    func unsubscribe(subscription: AnyObject, completion: (result: EmptyResult) -> Void ) {
        dispatch_barrier_async(_concurrentSubscriptionQueue, { () -> Void in
            if let subscription = subscription as? Subscription {
                self._subscriptions.removeValueForKey(subscription.subscriptionID)
                self.startStopHTTPServerIfNeeded()
            }
        })
    }
    
    internal func handleIncomingEvent(eventData: NSData) {
        
    }
    
    @objc private func applicationDidEnterBackground(notification: NSNotification){
        if _httpServer.isRunning() {
            _httpServer.stop()
        }
    }
    
    @objc private func applicationWillEnterForeground(notification: NSNotification){
        startStopHTTPServerIfNeeded()
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
}

extension UPnPEventSubscriptionManager.Subscription: Equatable { }

private func ==(lhs: UPnPEventSubscriptionManager.Subscription, rhs: UPnPEventSubscriptionManager.Subscription) -> Bool {
    return lhs.subscriptionID == rhs.subscriptionID
}
