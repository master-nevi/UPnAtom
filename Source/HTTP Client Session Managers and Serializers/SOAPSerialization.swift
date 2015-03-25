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

class SOAPRequestSerializer: AFHTTPRequestSerializer {
    class Parameters {
        let soapAction: String
        let serviceURN: String
        let arguments: NSDictionary?
        
        init(soapAction: String, serviceURN: String, arguments: NSDictionary?) {
            self.soapAction = soapAction
            self.serviceURN = serviceURN
            self.arguments = arguments
        }
    }
    
    override func requestBySerializingRequest(request: NSURLRequest!, withParameters parameters: AnyObject!, error: NSErrorPointer) -> NSURLRequest! {
        let requestParameters: Parameters! = parameters as? Parameters
        if requestParameters == nil {
            return nil
        }
        
        var mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.HTTPRequestHeaders {
            if let field = field as? String {
                if request.valueForHTTPHeaderField(field) == nil {
                    if let value = value as? String {
                        mutableRequest.setValue(value, forHTTPHeaderField: field)
                    }
                }
            }
        }
        
        if mutableRequest.valueForHTTPHeaderField("Content-Type") == nil {
            var charSet = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
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
        
        mutableRequest.setValue("\(count(body.utf8))", forHTTPHeaderField: "Content-Length")
        
        mutableRequest.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        return mutableRequest
    }
}

class SOAPResponseSerializer: AFXMLParserResponseSerializer {    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
        if !validateResponse(response as! NSHTTPURLResponse, data: data, error: error) {
            if error == nil {
                return nil
            }
        }
        
        var serializationError: NSError?
        var responseObject: AnyObject!
        let xmlParser = SOAPResponseParser()
        
        switch xmlParser.parse(soapResponseData: data) {
        case .Success(let value):
            responseObject = value()
        case .Failure(let error):
            serializationError = error
        }
        
        if serializationError != nil && error != nil {
            error.memory = serializationError!
        }
        
        return responseObject
    }
}

class SOAPResponseParser: AbstractDOMXMLParser {
    private var _responseParameters = [String: String]()
    
    override func parse(#document: ONOXMLDocument) -> EmptyResult {
        var result: EmptyResult = .Success
        document.enumerateElementsWithXPath("/s:Envelope/s:Body/*/*", usingBlock: { (element: ONOXMLElement!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if element.tag != nil && element.stringValue() != nil && count(element.tag) > 0 && count(element.stringValue()) > 0 {
                self._responseParameters[element.tag] = element.stringValue()
            }
            
            result = .Success
        })
        
        LogVerbose("SOAP response values: \(prettyPrint(_responseParameters))")
        
        return result
    }
    
    func parse(#soapResponseData: NSData) -> Result<[String: String]> {
        switch super.parse(data: soapResponseData) {
        case .Success:
            return .Success(_responseParameters)
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
