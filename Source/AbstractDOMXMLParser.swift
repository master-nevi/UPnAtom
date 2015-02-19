//
//  AbstractDOMXMLParser.swift
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

class AbstractDOMXMLParser {
    private(set) var defaultNamespace: [String: String]?
    let customDefaultNamespacePrefix: String
    
    init(customDefaultNamespacePrefix: String = "u") {
        self.customDefaultNamespacePrefix = customDefaultNamespacePrefix
    }
    
    func parse(#data: NSData) -> EmptyResult {
        var parserResult: EmptyResult = .Failure(createError("Parser failure"))
        autoreleasepool { () -> () in
            var parseError: NSError?
            let xmlDocument = GDataXMLDocument(data: data, error: &parseError)
            self.defaultNamespace = xmlDocument.rootElement().customDefaultNamespace(prefix: self.customDefaultNamespacePrefix)
            parserResult = parseError != nil ? EmptyResult.Failure(parseError!) : self.parse(document: xmlDocument)
        }
        
        return parserResult
    }
    
    func parse(#contentsOfURL: NSURL) -> EmptyResult {
        var parserResult: EmptyResult = .Failure(createError("Parser failure"))
        autoreleasepool { () -> () in
            if let data = NSData(contentsOfURL: contentsOfURL) {
                var parseError: NSError?
                let xmlDocument = GDataXMLDocument(data: data, error: &parseError)
                self.defaultNamespace = xmlDocument.rootElement().customDefaultNamespace(prefix: self.customDefaultNamespacePrefix)
                parserResult = parseError != nil ? EmptyResult.Failure(parseError!) : self.parse(document: xmlDocument)
            }
        }
        
        return parserResult
    }
    
    internal func parse(#document: GDataXMLDocument) -> EmptyResult {
        fatalError("Implement in subclass")
    }
    
    // MARK: - Internal lib
    
}

extension GDataXMLDocument {
    func enumerateNodes(xPath: String, closure: (node: GDataXMLNode) -> Void, failure: (error: NSError) -> Void) {
        self.enumerateNodes(xPath, namespaces: nil, closure: closure, failure: failure)
    }
    
    func enumerateNodes(xPath: String, namespaces: [String: String]?, closure: (node: GDataXMLNode) -> Void, failure: (error: NSError) -> Void) {
        var xPathError: NSError?
        if let nodes = self.nodesForXPath(xPath, namespaces: namespaces, error: &xPathError) {
            for node in nodes {
                if let node = node as? GDataXMLNode {
                    closure(node: node)
                }
            }
        }
        
        if let xPathError = xPathError {
            failure(error: xPathError)
        }
    }
}

extension GDataXMLNode {
    func enumerateNodes(xPath: String, closure: (node: GDataXMLNode) -> Void, failure: (error: NSError) -> Void) {
        self.enumerateNodes(xPath, namespaces: nil, closure: closure, failure: failure)
    }
    
    func enumerateNodes(xPath: String, namespaces: [String: String]?, closure: (node: GDataXMLNode) -> Void, failure: (error: NSError) -> Void) {
        var xPathError: NSError?
        if let nodes = self.nodesForXPath(xPath, namespaces: namespaces, error: &xPathError) {
            for node in nodes {
                if let node = node as? GDataXMLNode {
                    closure(node: node)
                }
            }
        }
        
        if let xPathError = xPathError {
            failure(error: xPathError)
        }
    }
}

extension GDataXMLElement {
    func defaultNamespaceURI() -> String? {
        for namespace in self.namespaces() {
            if let namespacePrefix = (namespace as? GDataXMLNode)?.name() {
                if countElements(namespacePrefix) == 0 {
                    return (namespace as? GDataXMLNode)?.stringValue()
                }
            }
        }
        
        return nil
    }
    
    func customDefaultNamespace(#prefix: String) -> [String: String]? {
        if let defaultNamespaceURI = self.defaultNamespaceURI() {
            return [prefix: defaultNamespaceURI]
        }
        
        return nil
    }
}
