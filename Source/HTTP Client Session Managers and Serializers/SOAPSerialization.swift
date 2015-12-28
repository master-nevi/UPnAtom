//
//  SOAPSerialization.swift
//  ControlPointDemo
//
//  SOAPSerialization.swift
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
import Ono

public class SOAPRequestSerializer: AFHTTPRequestSerializer {
    public class Parameters {
        let soapAction: String
        let serviceURN: String
        let arguments: NSDictionary?
        
        public init(soapAction: String, serviceURN: String, arguments: NSDictionary?) {
            self.soapAction = soapAction
            self.serviceURN = serviceURN
            self.arguments = arguments
        }
    }
    
    override public func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!) throws -> NSURLRequest {
        guard let requestParameters = parameters as? Parameters else {
            throw createError("Invalid parameters")
        }
        
        let mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.HTTPRequestHeaders {
            if let field = field as? String, value = value as? String where request.valueForHTTPHeaderField(field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        if mutableRequest.valueForHTTPHeaderField("Content-Type") == nil {
            let charSet = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
            mutableRequest.setValue("text/xml; charset=\"\(charSet)\"", forHTTPHeaderField: "Content-Type")
        }
        
        mutableRequest.setValue("\"\(requestParameters.serviceURN)#\(requestParameters.soapAction)\"", forHTTPHeaderField: "SOAPACTION")
        
        var body = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
        body += "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
        body += "<s:Body>"
        body += "<u:\(requestParameters.soapAction) xmlns:u=\"\(requestParameters.serviceURN)\">"
        if let arguments = requestParameters.arguments {
            for (key, value) in arguments {
                body += "<\(key)>\(value)</\(key)>"
            }
        }
        body += "</u:\(requestParameters.soapAction)>"
        body += "</s:Body></s:Envelope>"
        LogVerbose("SOAP request body: \(body)")
        
        mutableRequest.setValue("\(body.utf8.count)", forHTTPHeaderField: "Content-Length")
        
        mutableRequest.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        return mutableRequest
    }
}

public class SOAPResponseSerializer: AFXMLParserResponseSerializer {
    override public func responseObjectForResponse(response: NSURLResponse!, data: NSData!) throws -> AnyObject {
        try validateResponse(response as! NSHTTPURLResponse, data: data)
        let xmlParser = SOAPResponseParser()
        
        switch xmlParser.parse(soapResponseData: data) {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error
        }
    }
}

class SOAPResponseParser: AbstractDOMXMLParser {
    private var _responseParameters = [String: String]()
    
    override func parse(document document: ONOXMLDocument) -> EmptyResult {
        var result: EmptyResult = .Success
        document.enumerateElementsWithXPath("/s:Envelope/s:Body/*/*", usingBlock: { (element: ONOXMLElement!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if let elementTag = element.tag, elementValue = element.stringValue() where
                elementTag.characters.count > 0 && elementValue.characters.count > 0 && elementValue != "NOT_IMPLEMENTED" {
                    self._responseParameters[elementTag] = elementValue
            }
            
            result = .Success
        })
        
        LogVerbose("SOAP response values: \(prettyPrint(_responseParameters))")
        
        return result
    }
    
    func parse(soapResponseData soapResponseData: NSData) -> Result<[String: String]> {
        switch super.parse(data: soapResponseData) {
        case .Success:
            return .Success(_responseParameters)
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
