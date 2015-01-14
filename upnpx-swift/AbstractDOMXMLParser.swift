//
//  AbstractDOMXMLParser.swift
//  ControlPointDemo
//
//  Created by David Robles on 1/6/15.
//  Copyright (c) 2015 David Robles. All rights reserved.
//

import Foundation

class AbstractDOMXMLParser {
    private(set) var defaultNamespace: [String: String]?
    let customDefaultNamespacePrefix: String
    
    init(customDefaultNamespacePrefix: String = "u") {
        self.customDefaultNamespacePrefix = customDefaultNamespacePrefix
    }
    
    func parse(#data: NSData) -> VoidResult {
        var parserResult: VoidResult = .Failure(createError("Parser failure"))
        autoreleasepool { () -> () in
            var parseError: NSError?
            let xmlDocument = GDataXMLDocument(data: data, error: &parseError)
            self.defaultNamespace = xmlDocument.rootElement().customDefaultNamespace(prefix: self.customDefaultNamespacePrefix)
            parserResult = parseError != nil ? VoidResult.Failure(parseError!) : self.parse(document: xmlDocument)
        }
        
        return parserResult
    }
    
    func parse(#contentsOfURL: NSURL) -> VoidResult {
        var parserResult: VoidResult = .Failure(createError("Parser failure"))
        autoreleasepool { () -> () in
            if let data = NSData(contentsOfURL: contentsOfURL) {
                var parseError: NSError?
                let xmlDocument = GDataXMLDocument(data: data, error: &parseError)
                self.defaultNamespace = xmlDocument.rootElement().customDefaultNamespace(prefix: self.customDefaultNamespacePrefix)
                parserResult = parseError != nil ? VoidResult.Failure(parseError!) : self.parse(document: xmlDocument)
            }
        }
        
        return parserResult
    }
    
    internal func parse(#document: GDataXMLDocument) -> VoidResult {
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
