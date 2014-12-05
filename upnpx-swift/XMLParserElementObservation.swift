//
//  BasicParserAsset.swift
//  upnpx
//
//  Created by David Robles on 11/12/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class XMLParserElementObservation_Swift {
    // public
    let didStartParsingElement: ((elementName: String, attributeDict: [NSObject : AnyObject]!) -> Void)?
    let didEndParsingElement: ((elementName: String) -> Void)?
    let foundInnerText: ((elementName: String, text: String) -> Void)?
    let elementPath: [String]
    var innerText: String? {
        return _innerText?
    }
    
    // private
    private var _innerText: String?
    
    init(elementPath: [String], didStartParsingElement: ((elementName: String, attributeDict: [NSObject : AnyObject]!) -> Void)?, didEndParsingElement: ((elementName: String) -> Void)?, foundInnerText: ((elementName: String, text: String) -> Void)?) {
        self.elementPath = elementPath
        if let didStartParsingElement = didStartParsingElement {
            self.didStartParsingElement = {[unowned self] (elementName: String, attributeDict: [NSObject : AnyObject]!) -> Void in
                // reset _innerText at the start of the element parse
                self._innerText = nil
                
                didStartParsingElement(elementName: elementName, attributeDict: attributeDict)
            }
        }
        self.didEndParsingElement = didEndParsingElement
        self.foundInnerText = foundInnerText
    }
    
    func appendInnerText(innerText: String) {
        if _innerText == nil {
            _innerText = ""
        }
        
        _innerText! += innerText
    }
}
