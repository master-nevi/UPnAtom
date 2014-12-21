//
//  BasicUPnPDevice.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/17/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class AbstractUPnPDevice_Swift: AbstractUPnP_Swift {
    struct IconDescription: Printable {
        let relativeURL: NSURL
        let width, height, depth: Int
        let mimeType: String
        var description: String {
            return "\(relativeURL.absoluteString!) (\(mimeType):\(width)x\(height))"
        }
    }
    
    // public
    let udn: String!
    let friendlyName: String!
    let manufacturer: String!
    let manufacturerURL: NSURL?
    let modelDescription: String?
    let modelName: String!
    let modelNumber: String?
    let modelURL: NSURL?
    let serialNumber: String?
    let iconDescriptions: [IconDescription]?
    override var baseURL: NSURL! {
        if let baseURL = _baseURLFromXML {
            return baseURL
        }
        return super.baseURL
    }
    
    // private
    private let _baseURLFromXML: NSURL?
    
    override init?(ssdpDevice: SSDPDBDevice_ObjC) {
        super.init(ssdpDevice: ssdpDevice)
        
        let deviceParser = UPnPDeviceParser_Swift(upnpDevice: self)
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
}

extension AbstractUPnPDevice_Swift: ExtendedPrintable {
    override var className: String { return "AbstractUPnPDevice_Swift" }
    override var description: String {
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
