//
//  PropertyPrinter.swift
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

public protocol ExtendedPrintable: CustomStringConvertible {
    var className: String { get }
}

public struct PropertyPrinter {
    private var _properties = [String: String]()
    
    public init() { }
    
    public mutating func add<T>(propertyName: String, property: T?) {
        _properties[propertyName] = prettyPrint(property)
    }
    
    public mutating func add<T: CustomStringConvertible>(propertyName: String, property: T?) {
        _properties[propertyName] = prettyPrint(property)
    }
    
    public mutating func add<T>(propertyName: String, property: [T]?) {
        _properties[propertyName] = prettyPrint(property)
    }
    
    public mutating func add<T: CustomStringConvertible>(propertyName: String, property: [T]?) {
        _properties[propertyName] = prettyPrint(property)
    }
    
    public mutating func add<K, V>(propertyName: String, property: [K: V]?) {
        _properties[propertyName] = prettyPrint(property)
    }
    
    public mutating func add<K, V: CustomStringConvertible>(propertyName: String, property: [K: V]?) {
        _properties[propertyName] = prettyPrint(property)
    }
    
    //    subscript(key: String) -> Any? { // subscripts can't be used as the subscript function can't be Generic only class/struct-wide generic declarations can be made which isn't useful here
    //        get {
    //            return nil
    //        }
    //        set {
    //            add(key, property: newValue)
    //        }
    //    }
}

extension PropertyPrinter: CustomStringConvertible {
    public var description: String {
        return dictionaryDescription(_properties, pointsToSymbol: "=")
    }
}

/// helpPrint(), dictionaryDescription(), and arrayDescription() have so many variants due to the limitation in the Swift for detecting swift-protocol conformance at runtime. This restriction will be removed in a future release of swift: http://stackoverflow.com/questions/26909974/protocols-why-is-objc-required-for-conformance-checking-and-optional-requireme
func prettyPrint<K, V>(someDictionary: [K: V]?) -> String {
    if let someDictionary = someDictionary {
        return prettyPrint(dictionaryDescription(someDictionary, pointsToSymbol: ":"))
    }
    
    return "nil"
}

func prettyPrint<K, V: CustomStringConvertible>(someDictionary: [K: V]?) -> String {
    if let someDictionary = someDictionary {
        return prettyPrint(dictionaryDescription(someDictionary, pointsToSymbol: ":"))
    }
    
    return "nil"
}

func prettyPrint<T: CustomStringConvertible>(someArray: [T]?) -> String {
    if let someArray = someArray {
        return prettyPrint(arrayDescription(someArray))
    }
    
    return "nil"
}

func prettyPrint<T>(someArray: [T]?) -> String {
    if let someArray = someArray {
        return prettyPrint(arrayDescription(someArray))
    }
    
    return "nil"
}

func prettyPrint<T: CustomStringConvertible>(something: T?) -> String {
    if let something = something {
        return something.description.stringByReplacingOccurrencesOfString("\n", withString: "\n\t", options: .LiteralSearch)
    }
    
    return "nil"
}

func prettyPrint<T>(something: T?) -> String {
    if let something = something {
        return "\(something)".stringByReplacingOccurrencesOfString("\n", withString: "\n\t", options: .LiteralSearch)
    }
    
    return "nil"
}

func dictionaryDescription<K, V: CustomStringConvertible>(properties: [K: V], pointsToSymbol: String) -> String {
    var description = "{ \n"
    for (key, value) in properties {
        let valueDescription = value.description.stringByReplacingOccurrencesOfString("\n", withString: "\n\t", options: .LiteralSearch)
        description += "\t\(key) \(pointsToSymbol) \(valueDescription) \n"
    }
    description += "}"
    return description
}

func dictionaryDescription<K, V>(properties: [K: V], pointsToSymbol: String) -> String {
    var description = "{ \n"
    for (key, value) in properties {
        description += "\t\(key) \(pointsToSymbol) \(value) \n"
    }
    description += "}"
    return description
}

func arrayDescription<T: CustomStringConvertible>(array: [T]) -> String {
    var description = "{ \n"
    for item in array {
        let itemDescription = item.description.stringByReplacingOccurrencesOfString("\n", withString: "\n\t", options: .LiteralSearch)
        description += "\t\(itemDescription)\n"
    }
    description += "}"
    return description
}

func arrayDescription<T>(array: [T]) -> String {
    var description = "{ \n"
    for item in array {
        description += "\t\(item)\n"
    }
    description += "}"
    return description
}
