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
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!, error: NSErrorPointer) -> NSURLRequest! {
        let requestParameters: Parameters! = parameters as? Parameters
        if requestParameters == nil {
            return nil
        }
        
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
        
        if let callBackString = requestParameters.callBack.absoluteString {
            mutableRequest.setValue("<\(callBackString)>", forHTTPHeaderField: "CALLBACK")
        }
        
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
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
        if !validateResponse(response as NSHTTPURLResponse, data: data, error: error) {
            if error == nil {
                return nil
            }
        }
        
        var serializationError: NSError?
        var responseObject: AnyObject!
        
        let subscriptionID: String! = (response as NSHTTPURLResponse).allHeaderFields["SID"] as? String
        let timeoutString: String! = (response as NSHTTPURLResponse).allHeaderFields["TIMEOUT"] as? String
        
        if subscriptionID != nil && timeoutString != nil {
            let secondKeywordRange: Range! = timeoutString.rangeOfString("Second-")
            let timeout = timeoutString.substringWithRange(Range(start: secondKeywordRange.endIndex, end: timeoutString.endIndex)).toInt()
            if let timeout = timeout {
                responseObject = Response(subscriptionID: subscriptionID, timeout: timeout)
            }
        }
            
        if responseObject == nil {
            serializationError = createError("Did not receive a valid subscription response")
        }
        
        if serializationError != nil && error != nil {
            error.memory = serializationError!
        }
        
        return responseObject
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
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!, error: NSErrorPointer) -> NSURLRequest! {
        let requestParameters: Parameters! = parameters as? Parameters
        if requestParameters == nil {
            return nil
        }
        
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
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
        if !validateResponse(response as NSHTTPURLResponse, data: data, error: error) {
            if error == nil {
                return nil
            }
        }
        
        var serializationError: NSError?
        var responseObject: AnyObject!
        
        let subscriptionID: String! = (response as NSHTTPURLResponse).allHeaderFields["SID"] as? String
        let timeoutString: String! = (response as NSHTTPURLResponse).allHeaderFields["TIMEOUT"] as? String
        
        if subscriptionID != nil && timeoutString != nil {
            let secondKeywordRange: Range! = timeoutString.rangeOfString("Second-")
            let timeout = timeoutString.substringWithRange(Range(start: secondKeywordRange.endIndex, end: timeoutString.endIndex)).toInt()
            if let timeout = timeout {
                responseObject = Response(subscriptionID: subscriptionID, timeout: timeout)
            }
        }
        
        if responseObject == nil {
            serializationError = createError("Did not receive a valid subscription response")
        }
        
        if serializationError != nil && error != nil {
            error.memory = serializationError!
        }
        
        return responseObject
    }
}

class UPnPEventUnsubscribeRequestSerializer: AFHTTPRequestSerializer {
    class Parameters {
        let subscriptionID: String
        
        init(subscriptionID: String) {
            self.subscriptionID = subscriptionID
        }
    }
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!, error: NSErrorPointer) -> NSURLRequest! {
        let requestParameters: Parameters! = parameters as? Parameters
        if requestParameters == nil {
            return nil
        }
        
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
        
        mutableRequest.setValue("\(requestParameters.subscriptionID)", forHTTPHeaderField: "SID")
        
        return mutableRequest
    }
}

class UPnPEventUnsubscribeResponseSerializer: AFHTTPResponseSerializer {
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
        if !validateResponse(response as NSHTTPURLResponse, data: data, error: error) {
            if error == nil {
                return nil
            }
        }
        
        return nil
    }
}
