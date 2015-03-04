//
//  UPnPEventHTTPConnection.swift
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
import CocoaHTTPServer
import CocoaAsyncSocket // required by the init method and therefore needed for having default property values

@objc class UPnPEventHTTPConnection: HTTPConnection {
    /// NOTE: Instances of HTTPConnection are recycled, make sure to reset property values at the end of every request i.e. HTTPConnection.httpResponseForMethod()
    
    override func supportsMethod(method: String!, atPath path: String!) -> Bool {
        return method.lowercaseString == "notify"
    }
    
    override func expectsRequestBodyFromMethod(method: String!, atPath path: String!) -> Bool {
        return true
    }
    
    override func httpResponseForMethod(method: String!, URI path: String!) -> NSObject! {
        if method.lowercaseString == "notify" && path == UPnPManager_Swift.sharedInstance.eventSubscriptionManager.eventCallBackPath {
            let request = _request()
            
//            println("ALL HEADERS: \(request.allHeaderFields())")
//            let eventDataString = NSString(data: request.body(), encoding: NSUTF8StringEncoding)
//            println("FINAL DATA SIZE: \(request.body().length)\n\(eventDataString) \nEND")
            
            // TODO: this should be done via a delegate protocol however CocoaHTTPServer doesn't make this easy to do in Swift
            UPnPManager_Swift.sharedInstance.eventSubscriptionManager.handleIncomingEvent(subscriptionID: request.headerField("SID"), eventData: request.body())
            
            return HTTPDataResponse(data: nil)
        }
        
        return super.httpResponseForMethod(method, URI: path)
    }
    
    override func prepareForBodyWithSize(contentLength: UInt64) {
//        println("body size: \(contentLength)")
    }
    
    override func processBodyData(postDataChunk: NSData!) {
//        let eventDataString = NSString(data: postDataChunk, encoding: NSUTF8StringEncoding)
//        println("\nAppend body with size: \(postDataChunk.length)\nDATA: \(eventDataString)\n\n")
        
        _request().appendData(postDataChunk)
    }
    
    override func finishBody() {
//        println("finished body")
    }
    
    // HTTPConnection only exposes the request as an instance variable which Swift can't access directly
    private func _request() -> HTTPMessage {
        let requestIVar = class_getInstanceVariable(HTTPConnection.self, "request".cStringUsingEncoding(NSUTF8StringEncoding))
        return object_getIvar(self, requestIVar) as HTTPMessage
    }
}
