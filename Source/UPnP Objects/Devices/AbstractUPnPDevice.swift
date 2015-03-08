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

public class AbstractUPnPDevice: AbstractUPnP {
    @objc public class IconDescription: Printable {
        public let relativeURL: NSURL
        public let width, height, depth: Int
        public let mimeType: String
        public var description: String {
            return "\(relativeURL.absoluteString!) (\(mimeType):\(width)x\(height))"
        }
        
        init(relativeURL: NSURL, width: Int, height: Int, depth: Int, mimeType: String) {
            self.relativeURL = relativeURL
            self.width = width
            self.height = height
            self.depth = depth
            self.mimeType = mimeType
        }
    }
    
    // public
    public let udn: String!
    public let friendlyName: String!
    public let manufacturer: String!
    public let manufacturerURL: NSURL?
    public let modelDescription: String?
    public let modelName: String!
    public let modelNumber: String?
    public let modelURL: NSURL?
    public let serialNumber: String?
    public let iconDescriptions: [IconDescription]?
    override public var baseURL: NSURL! {
        if let baseURL = _baseURLFromXML {
            return baseURL
        }
        return super.baseURL
    }
    
    // private
    private let _baseURLFromXML: NSURL?
    
    required public init?(uuid: String, urn: String, usn: UniqueServiceName, xmlLocation: NSURL, upnpDescriptionXML: NSData) {
        super.init(uuid: uuid, urn: urn, usn: usn, xmlLocation: xmlLocation, upnpDescriptionXML: upnpDescriptionXML)
        
        let deviceParser = UPnPDeviceParser(upnpDevice: self, upnpDescriptionXML: upnpDescriptionXML)
        let parsedDevice = deviceParser.parse().value
        
        if let udn = parsedDevice?.udn {
            self.udn = udn
        }
        else { return nil }
        
        if let baseURL = parsedDevice?.baseURL {
            _baseURLFromXML = baseURL
        }
        
        if let friendlyName = parsedDevice?.friendlyName {
            self.friendlyName = friendlyName
        }
        else { return nil }
        
        if let manufacturer = parsedDevice?.manufacturer {
            self.manufacturer = manufacturer
        }
        else { return nil }
        
        self.manufacturerURL = parsedDevice?.manufacturerURL
        self.modelDescription = parsedDevice?.modelDescription
        
        if let modelName = parsedDevice?.modelName {
            self.modelName = modelName
        }
        else { return nil }
        
        self.modelNumber = parsedDevice?.modelNumber
        self.modelURL = parsedDevice?.modelURL
        self.serialNumber = parsedDevice?.serialNumber
        self.iconDescriptions = parsedDevice?.iconDescriptions
    }
    
    func serviceFor(#urn: String) -> AbstractUPnPService? {
        return UPnPManager_Swift.sharedInstance.upnpRegistry.serviceFor(usn: UniqueServiceName(uuid: uuid, urn: urn))
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isAbstractUPnPDevice() -> Bool {
        return self is AbstractUPnPDevice
    }
}

extension AbstractUPnPDevice: ExtendedPrintable {
    override public var className: String { return "AbstractUPnPDevice" }
    override public var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
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
