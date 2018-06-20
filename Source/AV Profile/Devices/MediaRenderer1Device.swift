//
//  MediaRenderer1Device.swift
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

open class MediaRenderer1Device: AbstractUPnPDevice {
    open var avTransportService: AVTransport1Service? {
        return service(forURN: "urn:schemas-upnp-org:service:AVTransport:1") as? AVTransport1Service
    }
    
    open var connectionManagerService: ConnectionManager1Service? {
        return service(forURN: "urn:schemas-upnp-org:service:ConnectionManager:1") as? ConnectionManager1Service
    }
    
    open var renderingControlService: RenderingControl1Service? {
        return service(forURN: "urn:schemas-upnp-org:service:RenderingControl:1") as? RenderingControl1Service
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isMediaRenderer1Device() -> Bool {
        return self is MediaRenderer1Device
    }
}

/// overrides ExtendedPrintable protocol implementation
extension MediaRenderer1Device {
    override public var className: String { return "\(type(of: self))" }
    override open var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
