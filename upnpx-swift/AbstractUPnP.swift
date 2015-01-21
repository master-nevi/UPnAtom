//
//  AbstractUPnP.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

@objc class AbstractUPnP: ExtendedPrintable {
    let uuid: String!
    let urn: String!
    let usn: UniqueServiceName!
    let xmlLocation: NSURL!
    var baseURL: NSURL! {
        return NSURL(string: "/", relativeToURL: xmlLocation)?.absoluteURL
    }
    
    init?(ssdpDevice: SSDPDBDevice_ObjC) {
        if let uuid = returnIfContainsElements(ssdpDevice.uuid) {
            self.uuid = uuid
        }
        else { return nil }
        
        if let urn = returnIfContainsElements(ssdpDevice.urn) {
            self.urn = urn
        }
        else { return nil }
        
        if let usn = returnIfContainsElements(ssdpDevice.usn) {
            self.usn = UniqueServiceName(uuid: uuid, urn: urn, customRawValue: usn)
        }
        else { return nil }
        
        if let xmlLocation = returnIfContainsElements(ssdpDevice.location) {
            self.xmlLocation = NSURL(string: xmlLocation)
        }
        else { return nil }
    }
}

extension AbstractUPnP: ExtendedPrintable {
    var className: String { return "AbstractUPnP" }
    var description: String {
        var properties = PropertyPrinter()
        properties.add("uuid", property: uuid)
        properties.add("urn", property: urn)
        properties.add("usn", property: usn.description)
        properties.add("xmlLocation", property: xmlLocation.absoluteString)
        properties.add("baseURL", property: baseURL.absoluteString)
        return properties.description
    }
}
