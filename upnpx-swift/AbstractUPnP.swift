//
//  AbstractUPnP.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

@objc class AbstractUPnP_Swift: ExtendedPrintable {
    let uuid: String!
    let urn: String!
    let usn: UniqueServiceName!
    let xmlLocation: NSURL!
    var baseURL: NSURL! {
        return NSURL(string: "/", relativeToURL: xmlLocation)?.absoluteURL
    }
    var className: String { return "AbstractUPnP_Swift" }
    var description: String {
        var properties = [String: String]()
        properties["uuid"] = uuid
        properties["urn"] = urn
        properties["usn"] = usn.description
        if let absoluteXMLLocation = xmlLocation.absoluteString { properties["xmlLocation"] = absoluteXMLLocation }
        if let absoluteBaseURL = baseURL.absoluteString { properties["baseURL"] = absoluteBaseURL }
        
        return stringDictionaryDescription(properties)
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
