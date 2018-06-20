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

/// TODO: For now rooting to NSObject to expose to Objective-C, see Github issue #16
open class AbstractUPnP: NSObject {
    open var uuid: String {
        return usn.uuid
    }
    open var urn: String {
        return usn.urn! // checked for nil during init
    }
    open let usn: UniqueServiceName
    open let descriptionURL: URL
    open var baseURL: URL! {
        return URL(string: "/", relativeTo: descriptionURL)?.absoluteURL
    }
    
    required public init?(usn: UniqueServiceName, descriptionURL: URL, descriptionXML: Data) {
        self.usn = usn
        self.descriptionURL = descriptionURL
        super.init()
        
        // only deal with UPnP object's with URN's for now, i.e. is either a device or service
        guard let urn = usn.urn, !urn.isEmpty else {
            return nil
        }
    }
}

public func ==(lhs: AbstractUPnP, rhs: AbstractUPnP) -> Bool {
    return lhs.usn == rhs.usn
}

extension AbstractUPnP {
    override open var hashValue: Int {
        return usn.hashValue
    }
    
    /// Because self is rooted to NSObject, for now, usage as a key in a dictionary will be treated as a key within an NSDictionary; which requires the overriding the methods hash and isEqual, see Github issue #16
    override open var hash: Int {
        return hashValue
    }
    
    /// Because self is rooted to NSObject, for now, usage as a key in a dictionary will be treated as a key within an NSDictionary; which requires the overriding the methods hash and isEqual, see Github issue #16
    override open func isEqual(_ object: Any?) -> Bool {
        if let other = object as? AbstractUPnP {
            return self == other
        }
        return false
    }
}

extension AbstractUPnP: ExtendedPrintable {
    #if os(iOS)
    public var className: String { return "\(type(of: self))" }
    #elseif os(OSX) // NSObject.className actually exists on OSX! Who knew.
    override public var className: String { return "\(type(of: self))" }
    #endif
    override open var description: String {
        var properties = PropertyPrinter()
        properties.add("uuid", property: uuid)
        properties.add("urn", property: urn)
        properties.add("usn", property: usn.description)
        properties.add("descriptionURL", property: descriptionURL.absoluteString)
        properties.add("baseURL", property: baseURL.absoluteString)
        return properties.description
    }
}
