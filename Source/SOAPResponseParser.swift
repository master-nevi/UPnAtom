//
//  SOAPResponseParser.swift
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

class SOAPResponseParser: AbstractDOMXMLParser {
    private var _responseParameters = [String: String]()
    
    override func parse(#document: GDataXMLDocument) -> EmptyResult {
        var result: EmptyResult!
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
