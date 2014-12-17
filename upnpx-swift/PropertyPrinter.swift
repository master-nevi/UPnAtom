//
//  PropertyPrinter.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/16/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

protocol ExtendedPrintable: Printable {
    var className: String { get }
}

struct PropertyPrinter {
    private var properties = [String: String]()
    
    mutating func add<T>(propertyName: String, property: T?) {
        properties[propertyName] = prettyPrint(property)
    }
    
    mutating func add<T: Printable>(propertyName: String, property: T?) {
        properties[propertyName] = prettyPrint(property)
    }
    
    mutating func add<T>(propertyName: String, property: [T]?) {
        properties[propertyName] = prettyPrint(property)
    }
    
    mutating func add<T: Printable>(propertyName: String, property: [T]?) {
        properties[propertyName] = prettyPrint(property)
    }
    
    mutating func add<K, V>(propertyName: String, property: [K: V]?) {
        properties[propertyName] = prettyPrint(property)
    }
    
    mutating func add<K, V: Printable>(propertyName: String, property: [K: V]?) {
        properties[propertyName] = prettyPrint(property)
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

extension PropertyPrinter: Printable {
    var description: String {
        return dictionaryDescription(properties, "=")
    }
}

/// helpPrint(), dictionaryDescription(), and arrayDescription() have so many variants due to the limitation in the Swift for detecting swift-protocol conformance at runtime. This restriction will be removed in a future release of swift: http://stackoverflow.com/questions/26909974/protocols-why-is-objc-required-for-conformance-checking-and-optional-requireme
func prettyPrint<K, V>(someDictionary: [K: V]?) -> String {
    if let someDictionary = someDictionary {
        return prettyPrint(dictionaryDescription(someDictionary, ":"))
    }
    
    return "nil"
}

func prettyPrint<K, V: Printable>(someDictionary: [K: V]?) -> String {
    if let someDictionary = someDictionary {
        return prettyPrint(dictionaryDescription(someDictionary, ":"))
    }
    
    return "nil"
}

func prettyPrint<T: Printable>(someArray: [T]?) -> String {
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

func prettyPrint<T: Printable>(something: T?) -> String {
    if let something = something {
        return something.description.stringByReplacingOccurrencesOfString("\n", replacement: "\n\t")
    }
    
    return "nil"
}

func prettyPrint<T>(something: T?) -> String {
    if let something = something {
        return "\(something)".stringByReplacingOccurrencesOfString("\n", replacement: "\n\t")
    }
    
    return "nil"
}

func dictionaryDescription<K, V: Printable>(properties: [K: V], pointsToSymbol: String) -> String {
    var description = "{ \n"
    for (key, value) in properties {
        let valueDescription = value.description.stringByReplacingOccurrencesOfString("\n", replacement: "\n\t")
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

func arrayDescription<T: Printable>(array: [T]) -> String {
    var description = "{ \n"
    for item in array {
        let itemDescription = item.description.stringByReplacingOccurrencesOfString("\n", replacement: "\n\t")
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

extension String {
    func stringByReplacingOccurrencesOfString(string: String, replacement: String) -> String {
        return self.stringByReplacingOccurrencesOfString(string, withString: replacement, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}
