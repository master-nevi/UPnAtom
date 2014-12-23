//
//  UPnPDeviceParser.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/24/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class UPnPDeviceParser_Swift: AbstractXMLParser_Swift {
    class ParserUPnPDevice {
        var udn: String?
        var baseURL: NSURL?
        var friendlyName: String?
        var manufacturer: String?
        var manufacturerURL: NSURL?
        var modelDescription: String?
        var modelName: String?
        var modelNumber: String?
        var modelURL: NSURL?
        var serialNumber: String?
        var iconDescriptions: [AbstractUPnPDevice_Swift.IconDescription] = []
        private var currentIconDescription: ParserIconDescription?
        init() { } // allow intializing with empty temp device
    }
    
    class ParserIconDescription {
        var relativeURL: NSURL?
        var width, height, depth: Int?
        var mimeType: String?
        init() { } // allow intializing with empty temp device
        var iconDescription: AbstractUPnPDevice_Swift.IconDescription? {
            if relativeURL != nil && width != nil && height != nil && depth != nil && mimeType != nil {
                return AbstractUPnPDevice_Swift.IconDescription(relativeURL: relativeURL!, width: width!, height: height!, depth: depth!, mimeType: mimeType!)
            }
            
            return nil
        }
    }
    
    private unowned let _upnpDevice: AbstractUPnPDevice_Swift
    private var _deviceStack = [ParserUPnPDevice]() // first is root device
    private var _foundDevice: ParserUPnPDevice?
    private var _baseURL: NSURL?
    private lazy var _numberFormatter = NSNumberFormatter()
    
    init(supportNamespaces: Bool, upnpDevice: AbstractUPnPDevice_Swift) {
        self._upnpDevice = upnpDevice
        super.init(supportNamespaces: supportNamespaces)
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["root", "URLBase"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._baseURL = NSURL(string: text)
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["root", "device"], didStartParsingElement: { [unowned self] (elementName, attributeDict) -> Void in
            self.didStartParsingDeviceElement()
        }, didEndParsingElement: { [unowned self] (elementName) -> Void in
            self.didEndParsingDeviceElement()
        }, foundInnerText: nil))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "deviceList", "device"], didStartParsingElement: { [unowned self] (elementName, attributeDict) -> Void in
            self.didStartParsingDeviceElement()
        }, didEndParsingElement: { [unowned self] (elementName) -> Void in
            self.didEndParsingDeviceElement()
        }, foundInnerText: nil))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "UDN"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.udn = text
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "friendlyName"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.friendlyName = text
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "modelDescription"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.modelDescription = text
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "modelName"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.modelName = text
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "modelNumber"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.modelNumber = text
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "modelURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.modelURL = NSURL(string: text)
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "serialNumber"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.serialNumber = text
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "manufacturer"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.manufacturer = text
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "device", "manufacturerURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.manufacturerURL = NSURL(string: text)
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "icon"], didStartParsingElement: { [unowned self] (elementName, attributeDict) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.currentIconDescription = ParserIconDescription()
        }, didEndParsingElement: { [unowned self] (elementName) -> Void in
            var currentDevice = self._deviceStack.last
            if let iconDescription = currentDevice?.currentIconDescription?.iconDescription {
                currentDevice?.iconDescriptions.append(iconDescription)
            }
            currentDevice?.currentIconDescription = nil
        }, foundInnerText: nil))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "icon", "mimetype"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.currentIconDescription?.mimeType = text
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "icon", "width"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            if let textNumber = self._numberFormatter.numberFromString(text) {
                var currentDevice = self._deviceStack.last
                currentDevice?.currentIconDescription?.width = Int(textNumber.intValue)
            }
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "icon", "height"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            if let textNumber = self._numberFormatter.numberFromString(text) {
                var currentDevice = self._deviceStack.last
                currentDevice?.currentIconDescription?.height = Int(textNumber.intValue)
            }
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "icon", "depth"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            if let textNumber = self._numberFormatter.numberFromString(text) {
                var currentDevice = self._deviceStack.last
                currentDevice?.currentIconDescription?.depth = Int(textNumber.intValue)
            }
        }))
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["*", "icon", "url"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.currentIconDescription?.relativeURL = NSURL(string: text)
        }))
    }
    
    convenience init(upnpDevice: AbstractUPnPDevice_Swift) {
        self.init(supportNamespaces: false, upnpDevice: upnpDevice)
    }
    
    func parse() -> Result<ParserUPnPDevice> {
        switch super.parse(contentsOfURL: _upnpDevice.xmlLocation) {
        case .Success:
            if let foundDevice = _foundDevice {
                foundDevice.baseURL = _baseURL
                return .Success(foundDevice)
            }
            else {
                return .Failure(createError("Parser error"))
            }
        case .Failure(let error):
            return .Failure(error)
        }
    }
    
    private func didStartParsingDeviceElement() {
        self._deviceStack.append(ParserUPnPDevice())
    }
    
    private func didEndParsingDeviceElement() {
        let poppedDevice = self._deviceStack.removeLast()
        
        if self._upnpDevice.uuid == poppedDevice.udn {
            _foundDevice = poppedDevice
        }
    }
}
