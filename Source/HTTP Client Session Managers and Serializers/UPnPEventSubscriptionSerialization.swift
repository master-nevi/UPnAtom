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
        let callBack: URL
        let timeout: Int // in seconds
        
        init(callBack: URL, timeout: Int) {
            self.callBack = callBack
            self.timeout = timeout
        }
    }
    
    override func request(bySerializingRequest request: URLRequest, withParameters parameters: Any?, error: NSErrorPointer) -> URLRequest? {
        guard let requestParameters = parameters as? Parameters else {
            return nil
        }
        
        let mutableRequest: NSMutableURLRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.httpRequestHeaders {
            if let field = field as? String, let value = value as? String, request.value(forHTTPHeaderField: field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        let callBackString = requestParameters.callBack.absoluteString
        mutableRequest.setValue("<\(callBackString)>", forHTTPHeaderField: "CALLBACK")
        
        mutableRequest.setValue("upnp:event", forHTTPHeaderField: "NT")
        mutableRequest.setValue("Second-\(requestParameters.timeout)", forHTTPHeaderField: "TIMEOUT")
        
        return mutableRequest as URLRequest
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
    
    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        do {
            try validate(response as! HTTPURLResponse, data: data)
        } catch {
            return nil
        }
        
        if let subscriptionID = (response as! HTTPURLResponse).allHeaderFields["SID"] as? String,
            let timeoutString = (response as! HTTPURLResponse).allHeaderFields["TIMEOUT"] as? String,
            let secondKeywordRange = timeoutString.range(of: "Second-"),
            let timeout = Int(timeoutString.substring(with: (secondKeywordRange.upperBound ..< timeoutString.endIndex))) {
            return Response(subscriptionID: subscriptionID, timeout: timeout)
        } else {
            return nil
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
    
    override func request(bySerializingRequest request: URLRequest, withParameters parameters: Any?, error: NSErrorPointer) -> URLRequest? {
        guard let requestParameters = parameters as? Parameters else {
            return nil
        }
        
        let mutableRequest: NSMutableURLRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.httpRequestHeaders {
            if let field = field as? String, let value = value as? String, request.value(forHTTPHeaderField: field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        mutableRequest.setValue("\(requestParameters.subscriptionID)", forHTTPHeaderField: "SID")
        mutableRequest.setValue("Second-\(requestParameters.timeout)", forHTTPHeaderField: "TIMEOUT")
        
        return mutableRequest as URLRequest
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
    
    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        do {
            try validate(response as! HTTPURLResponse, data: data)
        } catch {
            return nil
        }
        
        guard let subscriptionID = (response as! HTTPURLResponse).allHeaderFields["SID"] as? String,
            let timeoutString = (response as! HTTPURLResponse).allHeaderFields["TIMEOUT"] as? String,
            let secondKeywordRange = timeoutString.range(of: "Second-"),
            let timeout = Int(timeoutString.substring(with: (secondKeywordRange.upperBound ..< timeoutString.endIndex))) else {
                return nil
        }
        
        return Response(subscriptionID: subscriptionID, timeout: timeout)
    }
}

class UPnPEventUnsubscribeRequestSerializer: AFHTTPRequestSerializer {
    class Parameters {
        let subscriptionID: String
        
        init(subscriptionID: String) {
            self.subscriptionID = subscriptionID
        }
    }
    
    override func request(bySerializingRequest request: URLRequest, withParameters parameters: Any?, error: NSErrorPointer) -> URLRequest? {
        guard let requestParameters = parameters as? Parameters else {
            return nil
        }
        
        let mutableRequest: NSMutableURLRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.httpRequestHeaders {
            if let field = field as? String, let value = value as? String, request.value(forHTTPHeaderField: field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        mutableRequest.setValue("\(requestParameters.subscriptionID)", forHTTPHeaderField: "SID")
        
        return mutableRequest as URLRequest
    }
}

class UPnPEventUnsubscribeResponseSerializer: AFHTTPResponseSerializer {
    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        do {
            try validate(response as! HTTPURLResponse, data: data)
        } catch {
            return nil
        }
        
        return "Success" as AnyObject
    }
}
