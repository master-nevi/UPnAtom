//
//  UPnPDeviceFactory.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class UPnPDeviceFactory_Swift {
    class func createDeviceFrom(ssdpDevice: SSDPDBDevice_ObjC) -> AbstractUPnPDevice_Swift? {
        switch ssdpDevice.urn {
        case .Some(let urn) where urn == "urn:schemas-upnp-org:device:MediaRenderer:1":
            return MediaRenderer1Device_Swift(ssdpDevice: ssdpDevice)
        case .Some(let urn) where urn == "urn:schemas-upnp-org:device:MediaServer:1":
            return MediaServer1Device_Swift(ssdpDevice: ssdpDevice)
        default:
            return AbstractUPnPDevice_Swift(ssdpDevice: ssdpDevice)
        }
    }
}
