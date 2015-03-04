//
//  UPnPDeviceParser.swift
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

class UPnPDeviceParser: AbstractSAXXMLParser {
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
        var iconDescriptions: [AbstractUPnPDevice.IconDescription] = []
        private var currentIconDescription: ParserIconDescription?
        init() { } // allow intializing with empty temp device
    }
    
    class ParserIconDescription {
        var relativeURL: NSURL?
        var width, height, depth: Int?
        var mimeType: String?
        init() { } // allow intializing with empty temp device
        var iconDescription: AbstractUPnPDevice.IconDescription? {
            if relativeURL != nil && width != nil && height != nil && depth != nil && mimeType != nil {
                return AbstractUPnPDevice.IconDescription(relativeURL: relativeURL!, width: width!, height: height!, depth: depth!, mimeType: mimeType!)
            }
            
            return nil
        }
    }
    
    private unowned let _upnpDevice: AbstractUPnPDevice
    private let _upnpDescriptionXML: NSData
    private var _deviceStack = [ParserUPnPDevice]() // first is root device
    private var _foundDevice: ParserUPnPDevice?
    private var _baseURL: NSURL?
    private lazy var _numberFormatter = NSNumberFormatter()
    
    init(supportNamespaces: Bool, upnpDevice: AbstractUPnPDevice, upnpDescriptionXML: NSData) {
        self._upnpDevice = upnpDevice
        self._upnpDescriptionXML = upnpDescriptionXML
        super.init(supportNamespaces: supportNamespaces)
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["root", "URLBase"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._baseURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["root", "device"], didStartParsingElement: { [unowned self] (elementName, attributeDict) -> Void in
            self.didStartParsingDeviceElement()
        }, didEndParsingElement: { [unowned self] (elementName) -> Void in
            self.didEndParsingDeviceElement()
        }, foundInnerText: nil))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "deviceList", "device"], didStartParsingElement: { [unowned self] (elementName, attributeDict) -> Void in
            self.didStartParsingDeviceElement()
        }, didEndParsingElement: { [unowned self] (elementName) -> Void in
            self.didEndParsingDeviceElement()
        }, foundInnerText: nil))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "UDN"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.udn = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "friendlyName"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.friendlyName = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "modelDescription"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.modelDescription = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "modelName"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.modelName = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "modelNumber"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.modelNumber = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "modelURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.modelURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serialNumber"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.serialNumber = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "manufacturer"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.manufacturer = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "manufacturerURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.manufacturerURL = NSURL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon"], didStartParsingElement: { [unowned self] (elementName, attributeDict) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.currentIconDescription = ParserIconDescription()
        }, didEndParsingElement: { [unowned self] (elementName) -> Void in
            var currentDevice = self._deviceStack.last
            if let iconDescription = currentDevice?.currentIconDescription?.iconDescription {
                currentDevice?.iconDescriptions.append(iconDescription)
            }
            currentDevice?.currentIconDescription = nil
        }, foundInnerText: nil))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "mimetype"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.currentIconDescription?.mimeType = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "width"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            if let textNumber = self._numberFormatter.numberFromString(text) {
                var currentDevice = self._deviceStack.last
                currentDevice?.currentIconDescription?.width = Int(textNumber.intValue)
            }
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "height"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            if let textNumber = self._numberFormatter.numberFromString(text) {
                var currentDevice = self._deviceStack.last
                currentDevice?.currentIconDescription?.height = Int(textNumber.intValue)
            }
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "depth"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            if let textNumber = self._numberFormatter.numberFromString(text) {
                var currentDevice = self._deviceStack.last
                currentDevice?.currentIconDescription?.depth = Int(textNumber.intValue)
            }
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "url"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            var currentDevice = self._deviceStack.last
            currentDevice?.currentIconDescription?.relativeURL = NSURL(string: text)
        }))
    }
    
    convenience init(upnpDevice: AbstractUPnPDevice, upnpDescriptionXML: NSData) {
        self.init(supportNamespaces: false, upnpDevice: upnpDevice, upnpDescriptionXML: upnpDescriptionXML)
    }
    
    func parse() -> Result<ParserUPnPDevice> {
        switch super.parse(data: _upnpDescriptionXML) {
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
