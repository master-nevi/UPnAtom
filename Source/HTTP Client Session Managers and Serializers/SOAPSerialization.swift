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

open class SOAPRequestSerializer: AFHTTPRequestSerializer {
    open class Parameters {
        let soapAction: String
        let serviceURN: String
        let arguments: [String: Any]?
        
        public init(soapAction: String, serviceURN: String, arguments: [String: Any]?) {
            self.soapAction = soapAction
            self.serviceURN = serviceURN
            self.arguments = arguments
        }
    }
    
    override open func request(bySerializingRequest request: URLRequest, withParameters parameters: Any?, error: NSErrorPointer) -> URLRequest? {
        guard let requestParameters = parameters as? Parameters else {
            return nil
        }
        
        let mutableRequest: NSMutableURLRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        
        for (field, value) in self.httpRequestHeaders {
            if let field = field as? String, let value = value as? String, request.value(forHTTPHeaderField: field) == nil {
                mutableRequest.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        if mutableRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            let charSet = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue))
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
        
        mutableRequest.httpBody = body.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        return mutableRequest as URLRequest
    }
}

open class SOAPResponseSerializer: AFXMLParserResponseSerializer {
    override open func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        do {
            try validate(response as! HTTPURLResponse, data: data)
        } catch {
            return nil
        }
        let xmlParser = SOAPResponseParser()
        
        guard let data = data else {
            return nil
        }
        
        switch xmlParser.parse(soapResponseData: data) {
        case .success(let value):
            return value
        case .failure(let error):
            return nil
        }
    }
}

class SOAPResponseParser: AbstractDOMXMLParser {
    fileprivate var _responseParameters = [String: String]()
    
    override func parse(document: ONOXMLDocument) -> EmptyResult {
        var result: EmptyResult = .success
        document.enumerateElements(withXPath: "/s:Envelope/s:Body/*/*", using: { (element, index, stop) -> Void in
            if let element = element, let elementTag = element.tag, let elementValue = element.stringValue(),
                elementTag.characters.count > 0 && elementValue.characters.count > 0 && elementValue != "NOT_IMPLEMENTED" {
                self._responseParameters[elementTag] = elementValue
            }
            
            result = .success
        })
        
        LogVerbose("SOAP response values: \(prettyPrint(_responseParameters))")
        
        return result
    }
    
    func parse(soapResponseData: Data) -> Result<[String: String]> {
        switch super.parse(data: soapResponseData) {
        case .success:
            return .success(_responseParameters)
        case .failure(let error):
            return .failure(error)
        }
    }
}
