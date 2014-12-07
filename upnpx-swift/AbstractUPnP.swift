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
    var className: String { return "AbstractUPnP_Swift" }
    var description: String {
        var properties = [String: String]()
        properties["uuid"] = uuid
        properties["urn"] = urn
        properties["usn"] = usn.description
        if let absoluteXMLLocation = xmlLocation.absoluteString { properties["xmlLocation"] = absoluteXMLLocation }
        
        return stringDictionaryDescription(properties)
    }
    
    init?(ssdpDevice: SSDPDBDevice_ObjC) {
        if let uuid = AbstractUPnP_Swift.returnIfUsable(ssdpDevice.uuid) {
            self.uuid = uuid
        }
        else { return nil }
        
        if let urn = AbstractUPnP_Swift.returnIfUsable(ssdpDevice.urn) {
            self.urn = urn
        }
        else { return nil }
        
        if let usn = AbstractUPnP_Swift.returnIfUsable(ssdpDevice.usn) {
            self.usn = UniqueServiceName(uuid: uuid, urn: urn, customRawValue: usn)
        }
        else { return nil }
        
        if let xmlLocation = AbstractUPnP_Swift.returnIfUsable(ssdpDevice.location) {
            self.xmlLocation = NSURL(string: xmlLocation)
        }
        else { return nil }
    }
    
    class func returnIfUsable<T: _CollectionType>(x: T?) -> T? {
        if let x = x {
            if countElements(x) > 0 {
                return x
            }
        }
        
        return nil
    }
}
