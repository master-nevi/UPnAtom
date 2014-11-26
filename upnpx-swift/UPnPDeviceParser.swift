//
//  UPnPDeviceParser.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/24/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class UPnPDeviceParser_Swift: AbstractXMLParser_Swift {
    struct ParserUPnPDevice {
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
        init() { } // allow intializing with empty temp device
    }
    
    unowned let upnpDevice: AbstractUPnPDevice_Swift
    var deviceStack = [ParserUPnPDevice]() // first is root device
    var foundDevice: ParserUPnPDevice?
    
    init(supportNamespaces: Bool, upnpDevice: AbstractUPnPDevice_Swift) {
        self.upnpDevice = upnpDevice
        super.init(supportNamespaces: supportNamespaces)
        
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["root", "device"], didStartParsingElement: { [unowned self] (elementName, attributeDict) -> Void in
            self.deviceStack.append(ParserUPnPDevice())
        }, didEndParsingElement: { (elementName) -> Void in
            if self.upnpDevice.uuid == self.deviceStack.first?.udn {
                
            }
        }, foundInnerText: nil))
    }
    
    convenience init(upnpDevice: AbstractUPnPDevice_Swift) {
        self.init(supportNamespaces: false, upnpDevice: upnpDevice)
    }
    
    func parse() -> (parserStatus: ParserStatus, parsedDevice: ParserUPnPDevice?) {
        var parseStatus = super.parseFrom(upnpDevice.xmlLocation)
        
        return (parseStatus, foundDevice)
    }
}
