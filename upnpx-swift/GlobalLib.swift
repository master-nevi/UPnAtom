//
//  GlobalLib.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/21/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

protocol ExtendedPrintable: Printable {
    var className: String { get }
}

func stringDictionaryDescription(properties: [String: String]) -> String {
    var description = "{ \n"
    for (key, value) in properties {
        description += "\t\(key) = \(value) \n"
    }
    description += "}"
    return description
}

func arrayDescription<T: Printable>(array: [T]) -> String {
    var description = "{ \n"
    for item in array {
        description += "\t\(item.description)\n"
    }
    description += "}"
    return description
}

func returnIfContainsElements<T: _CollectionType>(x: T?) -> T? {
    if let x = x {
        if countElements(x) > 0 {
            return x
        }
    }
    
    return nil
}

extension String {
    func rangesOfString(findStr:String) -> [Range<String.Index>] {
        var arr = [Range<String.Index>]()
        var startInd = self.startIndex
        var i = 0
        // test first of all whether the string is likely to appear at all
        if contains(self, first(findStr)!) {
            startInd = find(self,first(findStr)!)!
        }
        else {
            return arr
        }
        // set starting point for search based on the finding of the first character
        i = distance(self.startIndex, startInd)
        while i<=countElements(self)-countElements(findStr) {
            if self[advance(self.startIndex, i)..<advance(self.startIndex, i+countElements(findStr))] == findStr {
                arr.append(Range(start:advance(self.startIndex, i),end:advance(self.startIndex, i+countElements(findStr))))
                i = i+countElements(findStr)
            }
            i++
        }
        return arr
    } // try further optimization by repeating the initial act of finding first character after each found string

    func stringByReplacingOccurrencesOfString(string:String, replacement:String) -> String {
        
        // get ranges first using rangesOfString: method, then glue together the string using ranges of existing string and old string
        
        let ranges = self.rangesOfString(string)
        // if the string isn't found return unchanged string
        if ranges.isEmpty {
            return self
        }
        
        var newString = ""
        var startInd = self.startIndex
        for r in ranges {
            
            newString += self[startInd..<minElement(r)]
            newString += replacement
            
            if maxElement(r) < self.endIndex {
                startInd = advance(maxElement(r),1)
            }
        }
        
        // add the last part of the string after the final find
        if maxElement(ranges.last!) < self.endIndex {
            newString += self[advance(maxElement(ranges.last!),1)..<self.endIndex]
        }
        
        return newString
    }
}
