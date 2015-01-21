//
//  UPnPDeviceFactory.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class UPnPFactory {
    class func createDeviceFrom(ssdpDevice: SSDPDBDevice_ObjC) -> AbstractUPnPDevice? {
        switch ssdpDevice.urn {
        case .Some(let urn) where urn == "urn:schemas-upnp-org:device:MediaRenderer:1":
            return MediaRenderer1Device_Swift(ssdpDevice: ssdpDevice)
        case .Some(let urn) where urn == "urn:schemas-upnp-org:device:MediaServer:1":
            return MediaServer1Device_Swift(ssdpDevice: ssdpDevice)
        default:
            return AbstractUPnPDevice(ssdpDevice: ssdpDevice)
        }
    }
    
    class func createServiceFrom(ssdpDevice: SSDPDBDevice_ObjC) -> AbstractUPnPService? {
        switch ssdpDevice.urn {
        case .Some(let urn) where urn == "urn:schemas-upnp-org:service:AVTransport:1":
            return AVTransport1Service(ssdpDevice: ssdpDevice)
        case .Some(let urn) where urn == "urn:schemas-upnp-org:service:ConnectionManager:1":
            return ConnectionManager1Service(ssdpDevice: ssdpDevice)
        case .Some(let urn) where urn == "urn:schemas-upnp-org:service:ContentDirectory:1":
            return ContentDirectory1Service(ssdpDevice: ssdpDevice)
        case .Some(let urn) where urn == "urn:schemas-upnp-org:service:RenderingControl:1":
            return RenderingControl1Service(ssdpDevice: ssdpDevice)
        default:
            return AbstractUPnPService(ssdpDevice: ssdpDevice)
        }
    }
}
