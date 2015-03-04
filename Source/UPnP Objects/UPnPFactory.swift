//
//  UPnPFactory.swift
//
//  Copyright (c) 2015 David Robles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import upnpx

class UPnPFactory {
    class func createUPnPObject(ssdpDevice: SSDPDBDevice_ObjC, upnpDescriptionXML: NSData) -> AbstractUPnP? {
        switch ssdpDevice.urn {
            // devices
        case .Some(let urn) where urn == "urn:schemas-upnp-org:device:MediaRenderer:1":
            return MediaRenderer1Device_Swift(ssdpObject: ssdpDevice, upnpDescriptionXML: upnpDescriptionXML)
        case .Some(let urn) where urn == "urn:schemas-upnp-org:device:MediaServer:1":
            return MediaServer1Device_Swift(ssdpObject: ssdpDevice, upnpDescriptionXML: upnpDescriptionXML)
            
            //services
        case .Some(let urn) where urn == "urn:schemas-upnp-org:service:AVTransport:1":
            return AVTransport1Service(ssdpObject: ssdpDevice, upnpDescriptionXML: upnpDescriptionXML)
        case .Some(let urn) where urn == "urn:schemas-upnp-org:service:ConnectionManager:1":
            return ConnectionManager1Service(ssdpObject: ssdpDevice, upnpDescriptionXML: upnpDescriptionXML)
        case .Some(let urn) where urn == "urn:schemas-upnp-org:service:ContentDirectory:1":
            return ContentDirectory1Service(ssdpObject: ssdpDevice, upnpDescriptionXML: upnpDescriptionXML)
        case .Some(let urn) where urn == "urn:schemas-upnp-org:service:RenderingControl:1":
            return RenderingControl1Service(ssdpObject: ssdpDevice, upnpDescriptionXML: upnpDescriptionXML)
        default:
            return AbstractUPnP(ssdpObject: ssdpDevice, upnpDescriptionXML: upnpDescriptionXML)
        }
    }
}
