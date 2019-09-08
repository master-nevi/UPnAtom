//
//  AbstractUPnPDevice.swift
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

open class AbstractUPnPDevice: AbstractUPnP {
    /// TODO: For now rooting to NSObject to expose to Objective-C, see Github issue #16
    open class IconDescription: CustomStringConvertible {
        public let relativeURL: URL
        public let size: CGSize
        public let colorDepth: Int
        public let mimeType: String
        open var description: String {
            return "\(relativeURL.absoluteString) (\(mimeType):\(size.width)x\(size.height))"
        }
        
        init(relativeURL: URL, size: CGSize, colorDepth: Int, mimeType: String) {
            self.relativeURL = relativeURL
            self.size = size
            self.colorDepth = colorDepth
            self.mimeType = mimeType
        }
    }
    
    // public
    open var deviceType: String {
        return urn
    }
    open var udn: String {
        return uuid
    }
    open fileprivate(set) var friendlyName: String! // TODO: Should ideally be a constant, see Github issue #10
    open fileprivate(set) var manufacturer: String! // TODO: Should ideally be a constant, see Github issue #10
    open fileprivate(set) var manufacturerURL: URL? // TODO: Should ideally be a constant, see Github issue #10
    open fileprivate(set) var modelDescription: String? // TODO: Should ideally be a constant, see Github issue #10
    open fileprivate(set) var modelName: String! // TODO: Should ideally be a constant, see Github issue #10
    open fileprivate(set) var modelNumber: String? // TODO: Should ideally be a constant, see Github issue #10
    open fileprivate(set) var modelURL: URL? // TODO: Should ideally be a constant, see Github issue #10
    open fileprivate(set) var serialNumber: String? // TODO: Should ideally be a constant, see Github issue #10
    open fileprivate(set) var iconDescriptions: [IconDescription]? // TODO: Should ideally be a constant, see Github issue #10
    open weak var serviceSource: UPnPServiceSource?
    override open var baseURL: URL! {
        if let baseURL = _baseURLFromXML {
            return baseURL
        }
        return super.baseURL as URL?
    }
    
    // private
    fileprivate var _baseURLFromXML: URL? // TODO: Should ideally be a constant, see Github issue #10
    
    required public init?(usn: UniqueServiceName, descriptionURL: URL, descriptionXML: Data) {
        super.init(usn: usn, descriptionURL: descriptionURL, descriptionXML: descriptionXML)
        
        let deviceParser = UPnPDeviceParser(upnpDevice: self, descriptionXML: descriptionXML)
        let parsedDevice = deviceParser.parse().value
        
        if let baseURL = parsedDevice?.baseURL {
            _baseURLFromXML = baseURL
        }
        
        guard let friendlyName = parsedDevice?.friendlyName,
            let manufacturer = parsedDevice?.manufacturer,
            let modelName = parsedDevice?.modelName else {
                return nil
        }
        
        self.friendlyName = friendlyName
        self.manufacturer = manufacturer
        self.modelName = modelName
        self.manufacturerURL = parsedDevice?.manufacturerURL
        self.modelDescription = parsedDevice?.modelDescription
        self.modelNumber = parsedDevice?.modelNumber
        self.modelURL = parsedDevice?.modelURL
        self.serialNumber = parsedDevice?.serialNumber
        self.iconDescriptions = parsedDevice?.iconDescriptions
    }
    /* Comment for confliction method swift 3.2 + unusage
    required public init?(usn: UniqueServiceName, descriptionURL: NSURL, descriptionXML: NSData) {
        fatalError("init(usn:descriptionURL:descriptionXML:) has not been implemented")
    } */
    
    open func service(forURN urn: String) -> AbstractUPnPService? {
        return serviceSource?.service(forUSN: UniqueServiceName(uuid: uuid, urn: urn)!)
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isAbstractUPnPDevice() -> Bool {
        return self is AbstractUPnPDevice
    }
}

/// overrides ExtendedPrintable protocol implementation
extension AbstractUPnPDevice {
    override public var className: String { return "\(type(of: self))" }
    override open var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        properties.add("deviceType", property: deviceType)
        properties.add("udn", property: udn)
        properties.add("friendlyName", property: friendlyName)
        properties.add("manufacturer", property: manufacturer)
        properties.add("manufacturerURL", property: manufacturerURL?.absoluteString)
        properties.add("modelDescription", property: modelDescription)
        properties.add("modelName", property: modelName)
        properties.add("modelNumber", property: modelNumber)
        properties.add("modelURL", property: modelURL?.absoluteString)
        properties.add("serialNumber", property: serialNumber)
        properties.add("iconDescriptions", property: iconDescriptions)
        return properties.description
    }
}

@objc public protocol UPnPServiceSource: class {
    func service(forUSN usn: UniqueServiceName) -> AbstractUPnPService?
}

class UPnPDeviceParser: AbstractSAXXMLParser {
    /// Using a class instead of struct since it's much easier and safer to continuously update from references than values from inside another container.
    class ParserUPnPDevice {
        var udn: String?
        var baseURL: URL?
        var friendlyName: String?
        var manufacturer: String?
        var manufacturerURL: URL?
        var modelDescription: String?
        var modelName: String?
        var modelNumber: String?
        var modelURL: URL?
        var serialNumber: String?
        var iconDescriptions: [AbstractUPnPDevice.IconDescription] = []
        fileprivate var _currentIconDescription: ParserIconDescription?
        init() { } // allow intializing with empty temp device
    }
    
    struct ParserIconDescription {
        var relativeURL: URL?
        var width, height, depth: Int?
        var mimeType: String?
        init() { } // allow intializing with empty temp device
        var iconDescription: AbstractUPnPDevice.IconDescription? {
            guard relativeURL != nil && width != nil && height != nil && depth != nil && mimeType != nil else {
                return nil
            }
            
            let size = CGSize(width: width!, height: height!)
            return AbstractUPnPDevice.IconDescription(relativeURL: relativeURL!, size: size, colorDepth: depth!, mimeType: mimeType!)
        }
    }
    
    fileprivate unowned let _upnpDevice: AbstractUPnPDevice
    fileprivate let _descriptionXML: Data
    fileprivate var _deviceStack = Stack<ParserUPnPDevice>() // first is root device
    fileprivate var _foundDevice: ParserUPnPDevice?
    fileprivate var _baseURL: URL?
    fileprivate lazy var _numberFormatter = NumberFormatter()
    
    init(supportNamespaces: Bool, upnpDevice: AbstractUPnPDevice, descriptionXML: Data) {
        self._upnpDevice = upnpDevice
        self._descriptionXML = descriptionXML
        super.init(supportNamespaces: supportNamespaces)
        
        /// NOTE: URLBase is deprecated in UPnP v2.0, baseURL should be derived from the SSDP discovery description URL
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["root", "URLBase"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._baseURL = URL(string: text)
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
            let currentDevice = self._deviceStack.peek()
            currentDevice?.udn = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "friendlyName"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?.friendlyName = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "modelDescription"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?.modelDescription = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "modelName"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?.modelName = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "modelNumber"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?.modelNumber = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "modelURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?.modelURL = URL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "serialNumber"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?.serialNumber = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "manufacturer"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?.manufacturer = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "device", "manufacturerURL"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?.manufacturerURL = URL(string: text)
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon"], didStartParsingElement: { [unowned self] (elementName, attributeDict) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?._currentIconDescription = ParserIconDescription()
            }, didEndParsingElement: { [unowned self] (elementName) -> Void in
                let currentDevice = self._deviceStack.peek()
                if let iconDescription = currentDevice?._currentIconDescription?.iconDescription {
                    currentDevice?.iconDescriptions.append(iconDescription)
                }
                currentDevice?._currentIconDescription = nil
            }, foundInnerText: nil))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "mimetype"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?._currentIconDescription?.mimeType = text
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "width"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            if let textNumber = self._numberFormatter.number(from: text) {
                let currentDevice = self._deviceStack.peek()
                currentDevice?._currentIconDescription?.width = Int(textNumber.int32Value)
            }
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "height"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            if let textNumber = self._numberFormatter.number(from: text) {
                let currentDevice = self._deviceStack.peek()
                currentDevice?._currentIconDescription?.height = Int(textNumber.int32Value)
            }
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "depth"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            if let textNumber = self._numberFormatter.number(from: text) {
                let currentDevice = self._deviceStack.peek()
                currentDevice?._currentIconDescription?.depth = Int(textNumber.int32Value)
            }
        }))
        
        self.addElementObservation(SAXXMLParserElementObservation(elementPath: ["*", "icon", "url"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            let currentDevice = self._deviceStack.peek()
            currentDevice?._currentIconDescription?.relativeURL = URL(string: text)
        }))
    }
    
    convenience init(upnpDevice: AbstractUPnPDevice, descriptionXML: Data) {
        self.init(supportNamespaces: false, upnpDevice: upnpDevice, descriptionXML: descriptionXML)
    }
    
    func parse() -> Result<ParserUPnPDevice> {
        switch super.parse(data: _descriptionXML) {
        case .success:
            if let foundDevice = _foundDevice {
                foundDevice.baseURL = _baseURL
                return .success(foundDevice)
            } else {
                return .failure(createError("Parser error"))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    fileprivate func didStartParsingDeviceElement() {
        self._deviceStack.push(ParserUPnPDevice())
    }
    
    fileprivate func didEndParsingDeviceElement() {
        let poppedDevice = self._deviceStack.pop()
        
        if self._upnpDevice.uuid == poppedDevice.udn {
            _foundDevice = poppedDevice
        }
    }
}
