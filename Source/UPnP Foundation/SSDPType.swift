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
    case all
    case rootDevice
    case uuid(String)
    case device(String)
    case service(String)
    
    typealias RawValue = String
    
    init?(rawValue: RawValue) {
        if rawValue == "ssdp:all" {
            self = .all
        } else if rawValue == "upnp:rootdevice" {
            self = .rootDevice
        } else if rawValue.range(of: "uuid:") != nil {
            self = .uuid(rawValue)
        } else if rawValue.range(of: ":device:") != nil {
            self = .device(rawValue)
        } else if rawValue.range(of: ":service:") != nil {
            self = .service(rawValue)
        } else {
            return nil
        }
    }
    
    init?(typeConstant: SSDPTypeConstant) {
        self.init(rawValue: typeConstant.rawValue)
    }
    
    var rawValue: RawValue {
        switch self {
        case .all:
            return "ssdp:all"
        case .rootDevice:
            return "upnp:rootdevice"
        case .uuid(let rawValue):
            return rawValue
        case .device(let rawValue):
            return rawValue
        case .service(let rawValue):
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
    case (.all, .all):
        return true
    case (.rootDevice, .rootDevice):
        return true
    case (.uuid(let lhsRawValue), .uuid(let rhsRawValue)):
        return lhsRawValue == rhsRawValue
    case (.device(let lhsRawValue), .device(let rhsRawValue)):
        return lhsRawValue == rhsRawValue
    case (.service(let lhsRawValue), .service(let rhsRawValue)):
        return lhsRawValue == rhsRawValue
    default:
        return false
    }
}
