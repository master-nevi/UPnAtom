//
//  AbstractSAXXMLParser.swift
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

// Subclassing NSObject in order to be a NSXMLParserDelegate
public class AbstractSAXXMLParser: NSObject {
    private let _supportNamespaces: Bool
    lazy private var _elementStack = [String]()
    lazy private var _elementObservations = [SAXXMLParserElementObservation]()
    
    public init(supportNamespaces: Bool) {
        _supportNamespaces = supportNamespaces
    }
    
    convenience override init() {
        self.init(supportNamespaces: false)
    }
    
    public func addElementObservation(elementObservation: SAXXMLParserElementObservation) {
        _elementObservations.append(elementObservation)
    }
    
    public func clearAllElementObservations() {
        _elementObservations.removeAll(keepCapacity: false)
    }
    
    func elementObservationForElementStack(elementStack: [String]) -> SAXXMLParserElementObservation? {
        for elementObservation in _elementObservations {
            // Full compares go first
            guard elementObservation.elementPath != elementStack else {
                return elementObservation
            }
            
            // * -> leafX -> leafY
            // Maybe we have a wildchar, that means that the path after the wildchar must match
            if elementObservation.elementPath.first == "*" &&
                elementStack.count >= elementObservation.elementPath.count {
                    var tempElementStack = elementStack
                    var tempObservationElementPath = elementObservation.elementPath
                    
                    // cut the * from our asset path
                    tempObservationElementPath.removeAtIndex(0)
                    
                    // make our (copy of the) curents stack the same length
                    let elementsToRemove: Int = tempElementStack.count - tempObservationElementPath.count
                    let range = Range(start: 0, end: elementsToRemove)
                    tempElementStack.removeRange(range)
                    if tempObservationElementPath == tempElementStack {
                        return elementObservation
                    }
            }
            
            // leafX -> leafY -> *
            if elementObservation.elementPath.last == "*" &&
                elementStack.count == elementObservation.elementPath.count && elementStack.count > 1 {
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
        
        return nil
    }
    
    public func parse(data data: NSData) -> EmptyResult {
        var parserResult: EmptyResult = .Failure(createError("Parser failure"))
        autoreleasepool { () -> () in
            if let validData = self.validateForParsing(data) {
                let parser = NSXMLParser(data: validData)
                parserResult = self.startParser(parser)
            }
        }
        
        return parserResult
    }
    
    // MARK: - Internal lib
    
    private func startParser(parser: NSXMLParser) -> EmptyResult {
        parser.shouldProcessNamespaces = _supportNamespaces
        parser.delegate = self
        
        var parserResult: EmptyResult = .Failure(createError("Parser failure"))
        if parser.parse() {
            parserResult = .Success
        } else {
            if let parserError = parser.parserError {
                parserResult = .Failure(parserError)
            }
        }
        
        parser.delegate = nil
        
        return parserResult
    }
    
    private func validateForParsing(data: NSData) -> NSData? {
        guard let xmlStringOptional = NSString(data: data, encoding: NSUTF8StringEncoding),
            let regexOptional = try? NSRegularExpression(pattern: "^\\s*$\\r?\\n", options: .AnchorsMatchLines) else {
                return nil
        }

        let validXMLString = regexOptional.stringByReplacingMatchesInString(xmlStringOptional as String, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, xmlStringOptional.length), withTemplate: "")
        return validXMLString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    }
}

extension AbstractSAXXMLParser: NSXMLParserDelegate {
    public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        _elementStack += [elementName]
        
        if let elementObservation = elementObservationForElementStack(_elementStack),
            didStartParsingElement = elementObservation.didStartParsingElement {
                didStartParsingElement(elementName: elementName, attributeDict: attributeDict)
        }
    }
    
    public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
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
        } else {
            LogError("XML badly formatted!")
            parser.abortParsing()
        }
    }
    
    public func parser(parser: NSXMLParser, foundCharacters string: String) {
        // The parser object may send the delegate several parser:foundCharacters: messages to report the characters of an element. Because string may be only part of the total character content for the current element, you should append it to the current accumulation of characters until the element changes.
        
        if let elementObservation = elementObservationForElementStack(_elementStack) {
            elementObservation.appendInnerText(string)
        }
    }
}
