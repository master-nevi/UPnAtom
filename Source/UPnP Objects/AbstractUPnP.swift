//
//  AbstractUPnP.swift
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

@objc public class AbstractUPnP {
    public let uuid: String!
    public let urn: String!
    public let usn: UniqueServiceName!
    public let xmlLocation: NSURL!
    public var baseURL: NSURL! {
        return NSURL(string: "/", relativeToURL: xmlLocation)?.absoluteURL
    }
    
    init?(ssdpDevice: SSDPDBDevice_ObjC) {
        if let uuid = returnIfContainsElements(ssdpDevice.uuid) {
            self.uuid = uuid
        }
        else { return nil }
        
        if let urn = returnIfContainsElements(ssdpDevice.urn) {
            self.urn = urn
        }
        else { return nil }
        
        if let usn = returnIfContainsElements(ssdpDevice.usn) {
            self.usn = UniqueServiceName(uuid: uuid, urn: urn, customRawValue: usn)
        }
        else { return nil }
        
        if let xmlLocation = returnIfContainsElements(ssdpDevice.location) {
            self.xmlLocation = NSURL(string: xmlLocation)
        }
        else { return nil }
    }
}

extension AbstractUPnP: ExtendedPrintable {
    public var className: String { return "AbstractUPnP" }
    public var description: String {
        var properties = PropertyPrinter()
        properties.add("uuid", property: uuid)
        properties.add("urn", property: urn)
        properties.add("usn", property: usn.description)
        properties.add("xmlLocation", property: xmlLocation.absoluteString)
        properties.add("baseURL", property: baseURL.absoluteString)
        return properties.description
    }
}
