//
//  UPnPServiceParser.swift
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

class UPnPServiceParser: AbstractSAXXMLParser {
    class ParserUPnPService {
        var baseURL: NSURL?
        var serviceType: String?
        var serviceID: String?
        var relativeDescriptionURL: NSURL?
        var relativeControlURL: NSURL?
        var relativeEventURL: NSURL?
    }
    
    private unowned let _upnpService: AbstractUPnPService
    private var _baseURL: NSURL?
    private var _currentParserService: ParserUPnPService?
    private var _foundParserService: ParserUPnPService?
    
    init(supportNamespaces: Bool, upnpService: AbstractUPnPService) {
        self._upnpService = upnpService
        super.init(supportNamespaces: supportNamespaces)
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["root", "URLBase"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._baseURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service"], didStartParsingElement: { (elementName, attributeDict) -> Void in
            self._currentParserService = ParserUPnPService()
        }, didEndParsingElement: { (elementName) -> Void in
            if let serviceType = self._currentParserService?.serviceType {
                if serviceType == self._upnpService.urn {
                    self._foundParserService = self._currentParserService
                }
            }
        }, foundInnerText: nil))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "serviceType"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.serviceType = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "serviceId"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.serviceID = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "SCPDURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.relativeDescriptionURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "controlURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.relativeControlURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serviceList", "service", "eventSubURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.relativeEventURL = NSURL(string: text)
        }))
    }
    
    convenience init(upnpService: AbstractUPnPService) {
        self.init(supportNamespaces: false, upnpService: upnpService)
    }
    
    func parse() -> Result<ParserUPnPService> {
        switch super.parse(contentsOfURL: _upnpService.xmlLocation) {
        case .Success:
            if let foundParserService = _foundParserService {
                foundParserService.baseURL = _baseURL
                return .Success(foundParserService)
            }
            else {
                return .Failure(createError("Parser error"))
            }
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
