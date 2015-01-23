//
//  UPnPEventSubscriptionSerialization.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/28/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class UPnPEventSubscribeRequestSerializer: AFHTTPRequestSerializer {
    let callBack: NSURL
    let timeout: Int // in seconds
    
    init(callBack: NSURL, timeout: Int) {
        self.callBack = callBack
        self.timeout = timeout
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        self.callBack = NSURL(string: aDecoder.decodeObjectOfClass(UPnPEventSubscribeRequestSerializer.self, forKey: "callBack") as String)!
        self.timeout = aDecoder.decodeIntegerForKey("timeout")
        super.init(coder: aDecoder)
    }
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!, error: NSErrorPointer) -> NSURLRequest! {
        var mutableRequest: NSMutableURLRequest = request.mutableCopy() as NSMutableURLRequest
        
        for (field, value) in self.HTTPRequestHeaders {
            if let field = field as? String {
                if request.valueForHTTPHeaderField(field) == nil {
                    if let value = value as? String {
                        mutableRequest.setValue(value, forHTTPHeaderField: field)
                    }
                }
            }
        }
        
        if let callBackString = callBack.absoluteString {
            mutableRequest.setValue("<\(callBackString)>", forHTTPHeaderField: "CALLBACK")
        }
        
        mutableRequest.setValue("upnp:event", forHTTPHeaderField: "NT")
        mutableRequest.setValue("Second-\(timeout)", forHTTPHeaderField: "TIMEOUT")
        
        return mutableRequest
    }
}

class UPnPEventSubscribeResponseSerializer: AFHTTPRequestSerializer {
    
}

class UPnPEventRenewSubscriptionRequestSerializer: AFHTTPRequestSerializer {
    let subscriptionID: String
    let timeout: Int // in seconds
    
    init(subscriptionID: String, timeout: Int) {
        self.subscriptionID = subscriptionID
        self.timeout = timeout
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        self.subscriptionID = aDecoder.decodeObjectOfClass(UPnPEventSubscribeRequestSerializer.self, forKey: "subscriptionID") as String
        self.timeout = aDecoder.decodeIntegerForKey("timeout")
        super.init(coder: aDecoder)
    }
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!, error: NSErrorPointer) -> NSURLRequest! {
        var mutableRequest: NSMutableURLRequest = request.mutableCopy() as NSMutableURLRequest
        
        for (field, value) in self.HTTPRequestHeaders {
            if let field = field as? String {
                if request.valueForHTTPHeaderField(field) == nil {
                    if let value = value as? String {
                        mutableRequest.setValue(value, forHTTPHeaderField: field)
                    }
                }
            }
        }
        
        mutableRequest.setValue("\(subscriptionID)", forHTTPHeaderField: "SID")
        mutableRequest.setValue("Second-\(timeout)", forHTTPHeaderField: "TIMEOUT")
        
        return mutableRequest
    }
}

class UPnPEventRenewSubscriptionResponseSerializer: AFHTTPRequestSerializer {
    
}

class UPnPEventUnsubscribeRequestSerializer: AFHTTPRequestSerializer {
    let subscriptionID: String
    
    init(subscriptionID: String, timeout: Int) {
        self.subscriptionID = subscriptionID
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        self.subscriptionID = aDecoder.decodeObjectOfClass(UPnPEventSubscribeRequestSerializer.self, forKey: "subscriptionID") as String
        super.init(coder: aDecoder)
    }
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!, error: NSErrorPointer) -> NSURLRequest! {
        var mutableRequest: NSMutableURLRequest = request.mutableCopy() as NSMutableURLRequest
        
        for (field, value) in self.HTTPRequestHeaders {
            if let field = field as? String {
                if request.valueForHTTPHeaderField(field) == nil {
                    if let value = value as? String {
                        mutableRequest.setValue(value, forHTTPHeaderField: field)
                    }
                }
            }
        }
        
        mutableRequest.setValue("\(subscriptionID)", forHTTPHeaderField: "SID")
        
        return mutableRequest
    }
}

class UPnPEventUnsubscribeResponseSerializer: AFHTTPRequestSerializer {
    
}
