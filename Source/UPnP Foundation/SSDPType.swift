//
//  SSDPType.swift
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

public enum SSDPTypeConstant: String {
    // General
    case All = "ssdp:all"
    case RootDevice = "upnp:rootdevice"
    
    // UPnP A/V profile
    case MediaServerDevice1 = "urn:schemas-upnp-org:device:MediaServer:1"
    case MediaRendererDevice1 = "urn:schemas-upnp-org:device:MediaRenderer:1"
    case ContentDirectory1Service = "urn:schemas-upnp-org:service:ContentDirectory:1"
    case ConnectionManager1Service = "urn:schemas-upnp-org:service:ConnectionManager:1"
    case RenderingControl1Service = "urn:schemas-upnp-org:service:RenderingControl:1"
    case AVTransport1Service = "urn:schemas-upnp-org:service:AVTransport:1"
}

enum SSDPType: RawRepresentable {
    case All
    case RootDevice
    case UUID(String)
    case Device(String)
    case Service(String)
    
    typealias RawValue = String
    
    init?(rawValue: RawValue) {
        if rawValue == "ssdp:all" {
            self = .All
        } else if rawValue == "upnp:rootdevice" {
            self = .RootDevice
        } else if rawValue.rangeOfString("uuid:") != nil {
            self = .UUID(rawValue)
        } else if rawValue.rangeOfString(":device:") != nil {
            self = .Device(rawValue)
        } else if rawValue.rangeOfString(":service:") != nil {
            self = .Service(rawValue)
        } else {
            return nil
        }
    }
    
    init?(typeConstant: SSDPTypeConstant) {
        self.init(rawValue: typeConstant.rawValue)
    }
    
    var rawValue: RawValue {
        switch self {
        case .All:
            return "ssdp:all"
        case .RootDevice:
            return "upnp:rootdevice"
        case .UUID(let rawValue):
            return rawValue
        case .Device(let rawValue):
            return rawValue
        case .Service(let rawValue):
            return rawValue
        }
    }
}

extension SSDPType: CustomStringConvertible {
    var description: String {
        return self.rawValue
    }
}

extension SSDPType: Hashable {
    var hashValue: Int {
        return self.rawValue.hashValue
    }
}

func ==(lhs: SSDPType, rhs: SSDPType) -> Bool {
    switch (lhs, rhs) {
    case (.All, .All):
        return true
    case (.RootDevice, .RootDevice):
        return true
    case (.UUID(let lhsRawValue), .UUID(let rhsRawValue)):
        return lhsRawValue == rhsRawValue
    case (.Device(let lhsRawValue), .Device(let rhsRawValue)):
        return lhsRawValue == rhsRawValue
    case (.Service(let lhsRawValue), .Service(let rhsRawValue)):
        return lhsRawValue == rhsRawValue
    default:
        return false
    }
}
