//
//  SoapRequestSerializer.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/16/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class SOAPRequestSerializer: AFHTTPRequestSerializer {
    let upnpNamespace = ""
    var soapAction = ""
    
    init(upnpNamespace: String) {
        super.init()
        self.upnpNamespace = upnpNamespace
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.upnpNamespace = aDecoder.decodeObjectOfClass(SOAPRequestSerializer.self, forKey: "upnpNamespace") as String
    }
    
    class func serializer(upnpNamespace: String) -> SOAPRequestSerializer {
        var serializer = SOAPRequestSerializer(upnpNamespace: upnpNamespace)
        
        return serializer
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
        
        if parameters != nil {
            if mutableRequest.valueForHTTPHeaderField("Content-Type") == nil {
                var charSet = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
                mutableRequest.setValue("text/xml; charset=\(charSet)", forHTTPHeaderField: "Content-Type")
            }
            
            mutableRequest.setValue("\"\(upnpNamespace)#\(soapAction)", forHTTPHeaderField: "SOAPACTION")
            
            var body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            body += "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            body += "<s:Body>"
            for (key, value) in parameters as NSDictionary {
                body += "<\(key)>\(value)</\(key)>"
            }
            body += "<u:\(soapAction) xmlns:u=\"\(upnpNamespace)\">"
            body += "</u:\(soapAction)>"
            body += "</s:Body></s:Envelope>"
            
            mutableRequest.setValue("\(countElements(body.utf8))", forHTTPHeaderField: "Content-Length")
            
            mutableRequest.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        }
        
        return mutableRequest
    }
}
