//
//  BasicUPnPDevice.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/17/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

struct UPnPDeviceIconDescription {
    let url: NSURL
    let width, height, depth: Int
}

class AbstractUPnPDevice_Swift: AbstractUPnP_Swift {
    // public
    let udn: String?
    let baseURL: NSURL!
    let friendlyName: String?
    let manufacturer: String?
    let manufacturerURL: NSURL?
    let modelDescription: String?
    let modelName: String?
    let modelNumber: String?
    let modelURL: NSURL?
    let serialNumber: String?
    let iconDescriptions: [UPnPDeviceIconDescription]?
    
    override init?(ssdpDevice: SSDPDBDevice_ObjC) {
        super.init(ssdpDevice: ssdpDevice)
    }
}
