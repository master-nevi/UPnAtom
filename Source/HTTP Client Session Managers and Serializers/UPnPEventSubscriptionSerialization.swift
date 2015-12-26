//
//  UPnPEventSubscriptionSerialization.swift
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

class UPnPEventSubscribeRequestSerializer: AFHTTPRequestSerializer {
    class Parameters {
        let callBack: NSURL
        let timeout: Int // in seconds
        
        init(callBack: NSURL, timeout: Int) {
            self.callBack = callBack
            self.timeout = timeout
        }
    }
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!) throws -> NSURLRequest {
        guard let requestParameters = parameters as? Parameters else {
            throw createError("Invalid parameters")
        }
        
        let mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.HTTPRequestHeaders {
            if let field = field as? String, value = value as? String where request.valueForHTTPHeaderField(field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        let callBackString = requestParameters.callBack.absoluteString
        mutableRequest.setValue("<\(callBackString)>", forHTTPHeaderField: "CALLBACK")
        
        mutableRequest.setValue("upnp:event", forHTTPHeaderField: "NT")
        mutableRequest.setValue("Second-\(requestParameters.timeout)", forHTTPHeaderField: "TIMEOUT")
        
        return mutableRequest
    }
}

class UPnPEventSubscribeResponseSerializer: AFHTTPResponseSerializer {
    class Response {
        let subscriptionID: String
        let timeout: Int // in seconds
        
        init(subscriptionID: String, timeout: Int) {
            self.subscriptionID = subscriptionID
            self.timeout = timeout
        }
    }
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!) throws -> AnyObject {
        try validateResponse(response as! NSHTTPURLResponse, data: data)
        
        if let subscriptionID = (response as! NSHTTPURLResponse).allHeaderFields["SID"] as? String,
            timeoutString = (response as! NSHTTPURLResponse).allHeaderFields["TIMEOUT"] as? String,
            secondKeywordRange = timeoutString.rangeOfString("Second-"),
            timeout = Int(timeoutString.substringWithRange(Range(start: secondKeywordRange.endIndex, end: timeoutString.endIndex))) {
            return Response(subscriptionID: subscriptionID, timeout: timeout)
        }
        else {
            throw createError("Did not receive a valid subscription response")
        }
    }
}

class UPnPEventRenewSubscriptionRequestSerializer: AFHTTPRequestSerializer {
    class Parameters {
        let subscriptionID: String
        let timeout: Int // in seconds
        
        init(subscriptionID: String, timeout: Int) {
            self.subscriptionID = subscriptionID
            self.timeout = timeout
        }
    }
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!) throws -> NSURLRequest {
        guard let requestParameters = parameters as? Parameters else {
            throw createError("Invalid parameters")
        }
        
        let mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.HTTPRequestHeaders {
            if let field = field as? String, value = value as? String where request.valueForHTTPHeaderField(field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        mutableRequest.setValue("\(requestParameters.subscriptionID)", forHTTPHeaderField: "SID")
        mutableRequest.setValue("Second-\(requestParameters.timeout)", forHTTPHeaderField: "TIMEOUT")
        
        return mutableRequest
    }
}

class UPnPEventRenewSubscriptionResponseSerializer: AFHTTPResponseSerializer {
    class Response {
        let subscriptionID: String
        let timeout: Int // in seconds
        
        init(subscriptionID: String, timeout: Int) {
            self.subscriptionID = subscriptionID
            self.timeout = timeout
        }
    }
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!) throws -> AnyObject {
        try validateResponse(response as! NSHTTPURLResponse, data: data)
        
        if let subscriptionID = (response as! NSHTTPURLResponse).allHeaderFields["SID"] as? String,
            timeoutString = (response as! NSHTTPURLResponse).allHeaderFields["TIMEOUT"] as? String,
            secondKeywordRange = timeoutString.rangeOfString("Second-"),
            timeout = Int(timeoutString.substringWithRange(Range(start: secondKeywordRange.endIndex, end: timeoutString.endIndex))) {
                return Response(subscriptionID: subscriptionID, timeout: timeout)
        }
        else {
            throw createError("Did not receive a valid subscription response")
        }
    }
}

class UPnPEventUnsubscribeRequestSerializer: AFHTTPRequestSerializer {
    class Parameters {
        let subscriptionID: String
        
        init(subscriptionID: String) {
            self.subscriptionID = subscriptionID
        }
    }
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!) throws -> NSURLRequest {
        guard let requestParameters = parameters as? Parameters else {
            throw createError("Invalid parameters")
        }
        
        let mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.HTTPRequestHeaders {
            if let field = field as? String, value = value as? String where request.valueForHTTPHeaderField(field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        mutableRequest.setValue("\(requestParameters.subscriptionID)", forHTTPHeaderField: "SID")
        
        return mutableRequest
    }
}

class UPnPEventUnsubscribeResponseSerializer: AFHTTPResponseSerializer {
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!) throws -> AnyObject {
        try validateResponse(response as! NSHTTPURLResponse, data: data)
        
        return "Success";
    }
}
