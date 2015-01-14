//
//  UPnPServiceParser.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/7/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class UPnPServiceParser_Swift: AbstractSAXXMLParser_Swift {
    class ParserUPnPService {
        var baseURL: NSURL?
        var serviceType: String?
        var serviceID: String?
        var relativeDescriptionURL: NSURL?
        var relativeControlURL: NSURL?
        var relativeEventURL: NSURL?
    }
    
    private unowned let _upnpService: AbstractUPnPService_Swift
    private var _baseURL: NSURL?
    private var _currentParserService: ParserUPnPService?
    private var _foundParserService: ParserUPnPService?
    
    init(supportNamespaces: Bool, upnpService: AbstractUPnPService_Swift) {
        self._upnpService = upnpService
        super.init(supportNamespaces: supportNamespaces)
        
        self.addElementObservation(SAXXMLParserElementObservation_Swift(elementPath: ["root", "URLBase"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._baseURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation_Swift(elementPath: ["*", "device", "serviceList", "service"], didStartParsingElement: { (elementName, attributeDict) -> Void in
            self._currentParserService = ParserUPnPService()
        }, didEndParsingElement: { (elementName) -> Void in
            if let serviceType = self._currentParserService?.serviceType {
                if serviceType == self._upnpService.urn {
                    self._foundParserService = self._currentParserService
                }
            }
        }, foundInnerText: nil))
        
        self.addElementObservation(SAXXMLParserElementObservation_Swift(elementPath: ["*", "device", "serviceList", "service", "serviceType"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.serviceType = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation_Swift(elementPath: ["*", "device", "serviceList", "service", "serviceId"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.serviceID = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation_Swift(elementPath: ["*", "device", "serviceList", "service", "SCPDURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.relativeDescriptionURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation_Swift(elementPath: ["*", "device", "serviceList", "service", "controlURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.relativeControlURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation_Swift(elementPath: ["*", "device", "serviceList", "service", "eventSubURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentService = self._currentParserService
            currentService?.relativeEventURL = NSURL(string: text)
        }))
    }
    
    convenience init(upnpService: AbstractUPnPService_Swift) {
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
