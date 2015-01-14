//
//  SOAPResponseParser.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/20/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class SOAPResponseParser: AbstractDOMXMLParser {
    private var _responseParameters = [String: String]()
    
    override func parse(#document: GDataXMLDocument) -> VoidResult {
        var result: VoidResult!
        document.enumerateNodes("/s:Envelope/s:Body/*/*", closure: { (node: GDataXMLNode) -> Void in
//            println("name: \(node.name()) string value: \(node.stringValue())")
            if node.name() != nil && node.stringValue() != nil && countElements(node.name()) > 0 && countElements(node.stringValue()) > 0 {
                self._responseParameters[node.name()] = node.stringValue()
            }
            
            result = .Success
            }, failure: { (error: NSError) -> Void in
            result = .Failure(error)
        })
        return result
    }
    
    func parse(#soapResponseData: NSData) -> Result<[String: String]> {
//        println("RESPONSE: \(NSString(data: soapResponseData, encoding: NSUTF8StringEncoding))")
        switch super.parse(data: soapResponseData) {
        case .Success:
            return .Success(_responseParameters)
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
