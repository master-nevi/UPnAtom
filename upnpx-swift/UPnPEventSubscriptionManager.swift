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
    private class Subscription {
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
    private let _concurrentSubscriptionQueue = dispatch_queue_create("com.upnpx-swift.upnp-event-subscription-manager.subscription-queue", DISPATCH_QUEUE_CONCURRENT)
    
    func subscribe(subscriber: UPnPEventSubscriber, eventURL: NSURL, completion: (subscription: Result<AnyObject>) -> Void) {
        let hasSubscriptionForEventURL: Bool = (_subscriptions.values.array as NSArray).filteredArrayUsingPredicate(NSPredicate(format: "eventURLString = %@", eventURL.absoluteString!)!).count > 0
        if hasSubscriptionForEventURL {
            completion(subscription: .Failure(createError("Subscription for event URL exists")))
            return
        }
    }
    
    func unsubscribe(subscription: AnyObject, completion: (result: VoidResult) -> Void ) {
        dispatch_barrier_async(_concurrentSubscriptionQueue, { () -> Void in
            if let subscription = subscription as? Subscription {
                self._subscriptions.removeValueForKey(subscription.subscriptionID)
            }
        })
    }
}

extension UPnPEventSubscriptionManager.Subscription: Equatable { }

private func ==(lhs: UPnPEventSubscriptionManager.Subscription, rhs: UPnPEventSubscriptionManager.Subscription) -> Bool {
    return lhs.subscriptionID == rhs.subscriptionID
}
