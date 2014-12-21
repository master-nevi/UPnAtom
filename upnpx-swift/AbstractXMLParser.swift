//
//  BasicParser.swift
//  upnpx
//
//  Created by David Robles on 11/12/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

// Subclassing NSObject in order to be a NSXMLParserDelegate
class AbstractXMLParser_Swift: NSObject {
    // public
    
    // private
    private let _supportNamespaces: Bool
    lazy private var _elementStack = [String]()
    lazy private var _elementObservations = [XMLParserElementObservation_Swift]()
    
    init(supportNamespaces: Bool) {
        _supportNamespaces = supportNamespaces
    }
    
    convenience override init() {
        self.init(supportNamespaces: false)
    }
    
    func addElementObservation(elementObservation: XMLParserElementObservation_Swift) {
        _elementObservations.append(elementObservation)
    }
    
    func clearAllElementObservations() {
        _elementObservations.removeAll(keepCapacity: false)
    }
    
    func elementObservationForElementStack(elementStack: [String]) -> XMLParserElementObservation_Swift? {
        for elementObservation in _elementObservations {
            // Full compares go first
            if elementObservation.elementPath == elementStack {
                return elementObservation
            }
            else {
                // * -> leafX -> leafY
                // Maybe we have a wildchar, that means that the path after the wildchar must match
                if elementObservation.elementPath.first == "*" {
                    if elementStack.count >= elementObservation.elementPath.count {
                        var tempElementStack = elementStack
                        var tempObservationElementPath = elementObservation.elementPath
                        
                        // cut the * from our asset path
                        tempObservationElementPath.removeAtIndex(0)
                        
                        // make our (copy of the) curents stack the same length
                        let elementsToRemove: Int = tempElementStack.count - tempObservationElementPath.count
                        var range = Range(start: 0, end: elementsToRemove)
                        tempElementStack.removeRange(range)
                        if tempObservationElementPath == tempElementStack {
                            return elementObservation
                        }
                    }
                }
                
                // leafX -> leafY -> *
                if elementObservation.elementPath.last == "*" {
                    if elementStack.count == elementObservation.elementPath.count && elementStack.count > 1 {
                        var tempElementStack = elementStack
                        var tempObservationElementPath = elementObservation.elementPath
                        // Cut the last entry (which is * in one array and <element> in the other
                        tempElementStack.removeLast()
                        tempObservationElementPath.removeLast()
                        if tempElementStack == tempObservationElementPath {
                            return elementObservation
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    func parse(#data: NSData) -> Result<Any> {
        var parserResult: Result<Any> = .Failure(AbstractXMLParser_Swift.createError("Parser failure"))
        autoreleasepool { () -> () in
            if let validData = self.validateForParsing(data) {
                let parser = NSXMLParser(data: validData)
                parserResult = self.startParser(parser)
            }
        }
        
        return parserResult
    }
    
    func parse(#contentsOfURL: NSURL) -> Result<Any> {
        var parserResult: Result<Any> = .Failure(AbstractXMLParser_Swift.createError("Parser failure"))
        autoreleasepool { () -> () in
            if let data = NSData(contentsOfURL: contentsOfURL) {
                if let validData = self.validateForParsing(data) {
                    let parser = NSXMLParser(data: validData)
                    parserResult = self.startParser(parser)
                }
            }
        }
        
        return parserResult
    }
    
    // MARK: - Internal lib
    
    internal class func createError(message: String) -> Error {
        return NSError(domain: "upnpx-swift", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    private func startParser(parser: NSXMLParser) -> Result<Any> {
        parser.shouldProcessNamespaces = _supportNamespaces
        parser.delegate = self
        
        var parserResult: Result<Any> = .Failure(AbstractXMLParser_Swift.createError("Parser failure"))
        if parser.parse() {
            parserResult = .NoContentSuccess
        }
        else {
            if let parserError = parser.parserError {
                parserResult = .Failure(parserError)
            }
        }
        
        parser.delegate = nil
        
        return parserResult
    }
    
    private func validateForParsing(data: NSData) -> NSData? {
        let xmlStringOptional = NSString(data: data, encoding: NSUTF8StringEncoding)
        var error: NSError?
        let regexOptional = NSRegularExpression(pattern: "^\\s*$\\r?\\n", options: .AnchorsMatchLines, error: &error)
        if xmlStringOptional != nil && regexOptional != nil {
            let validXMLString = regexOptional!.stringByReplacingMatchesInString(xmlStringOptional!, options: NSMatchingOptions(0), range: NSMakeRange(0, xmlStringOptional!.length), withTemplate: "")
            return validXMLString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        }
        
        return nil
    }
}

extension AbstractXMLParser_Swift: NSXMLParserDelegate {
    internal func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
        _elementStack += [elementName]
        
        if let elementObservation = elementObservationForElementStack(_elementStack) {
            if let didStartParsingElement = elementObservation.didStartParsingElement {
                didStartParsingElement(elementName: elementName, attributeDict: attributeDict)
            }
        }
    }
    
    internal func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        if let elementObservation = elementObservationForElementStack(_elementStack) {
            let foundInnerText = elementObservation.foundInnerText
            let innerText = elementObservation.innerText
            if foundInnerText != nil && innerText != nil {
                foundInnerText!(elementName: elementName, text: elementObservation.innerText!)
            }
            
            if let didEndParsingElement = elementObservation.didEndParsingElement {
                didEndParsingElement(elementName: elementName)
            }
        }
        
        if elementName == _elementStack.last {
            _elementStack.removeLast()
        }
        else {
            println("XML badly formatted!")
            parser.abortParsing()
        }
    }
    
    internal func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        // The parser object may send the delegate several parser:foundCharacters: messages to report the characters of an element. Because string may be only part of the total character content for the current element, you should append it to the current accumulation of characters until the element changes.
        
        if let elementObservation = elementObservationForElementStack(_elementStack) {
            elementObservation.appendInnerText(string)
        }
    }
}
