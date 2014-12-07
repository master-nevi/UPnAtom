//
//  AbstractUPnPService.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class AbstractUPnPService_Swift: AbstractUPnP_Swift {
    override init?(ssdpDevice: SSDPDBDevice_ObjC) {
        super.init(ssdpDevice: ssdpDevice)
        
        let serviceParser = UPnPServiceParser_Swift(upnpService: self)
    }
}
