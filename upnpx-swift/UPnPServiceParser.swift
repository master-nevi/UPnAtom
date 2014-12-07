//
//  UPnPServiceParser.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/7/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class UPnPServiceParser_Swift: AbstractXMLParser_Swift {
    class ParserUPnPService {
        
    }
    
    unowned let upnpService: AbstractUPnPService_Swift
    
    init(supportNamespaces: Bool, upnpService: AbstractUPnPService_Swift) {
        self.upnpService = upnpService
        super.init(supportNamespaces: supportNamespaces)
        
    }
    
    convenience init(upnpService: AbstractUPnPService_Swift) {
        self.init(supportNamespaces: false, upnpService: upnpService)
    }
    
//    func parse() -> (parserStatus: ParserStatus, parsedService: ParserUPnPService?) {
//        var parseStatus = super.parseFrom(upnpDevice.xmlLocation)
//        
//        foundDevice?.baseURL = baseURL
//        
//        return (parseStatus, foundDevice)
//    }
}
