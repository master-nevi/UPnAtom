//
//  UPnPEventHTTPConnection.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/28/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

@objc class UPnPEventHTTPConnection: HTTPConnection {
    let callBackPath = "/Event"
    let bodyData = NSMutableData()
    
    override func supportsMethod(method: String!, atPath path: String!) -> Bool {
        return method.lowercaseString == "notify"
    }
    
    override func expectsRequestBodyFromMethod(method: String!, atPath path: String!) -> Bool {
        return true
    }
    
    override func httpResponseForMethod(method: String!, URI path: String!) -> NSObject! {
        if method.lowercaseString == "notify" && path == callBackPath {
            // TODO: this should be done via a delegate protocol however CocoaHTTPServer doesn't make this easy to do in Swift
            UPnPManager_Swift.sharedInstance.eventSubscriptionManager.handleIncomingEvent(bodyData)
            
            return HTTPDataResponse(data: nil)
        }
        
        return super.httpResponseForMethod(method, URI: path)
    }
    
    override func processBodyData(postDataChunk: NSData!) {
        bodyData.appendData(postDataChunk)
    }
}
