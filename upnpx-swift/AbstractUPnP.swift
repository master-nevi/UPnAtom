//
//  AbstractUPnP.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class AbstractUPnP_Swift {
    let uuid: String!
    let urn: String!
    let usn: String!
    let xmlLocation: NSURL!
    
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
            self.usn = usn
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
