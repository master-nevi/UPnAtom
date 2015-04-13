//
//  UniqueServiceName.swift
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

@objc public class UniqueServiceName: RawRepresentable {
    public let rawValue: RawValue
    public let uuid: String
    public let urn: String?
    public let rootDevice: Bool
    
    public typealias RawValue = String
    
    public required init?(rawValue: RawValue) {
        self.rawValue = rawValue
        
        // all forms of usn should contain a uuid, otherwise it's invalid and nil will be returned
        if let uuid = returnIfContainsElements(UniqueServiceName.uuid(usn: rawValue)) {
            self.uuid = uuid
        }
        else {
            /// TODO: Remove default initializations to simply return nil, see Github issue #11
            self.uuid = ""
            self.rootDevice = false
            self.urn = nil
            return nil
        }
        
        rootDevice = UniqueServiceName.isRootDevice(usn: rawValue)
        urn = returnIfContainsElements(UniqueServiceName.urn(usn: rawValue))
    }
    
    convenience init?(uuid: String, urn: String) {
        self.init(rawValue: "\(uuid)::\(urn)")
    }
    
    convenience init?(uuid: String, rootDevice: Bool) {
        let rawValue = rootDevice ? "\(uuid)::upnp:rootdevice" : "\(uuid)"
        self.init(rawValue: rawValue)
    }
    
    class func uuid(#usn: String) -> String? {
        let usnComponents = usn.componentsSeparatedByString("::")
        return (usnComponents.count >= 1 && usnComponents[0].rangeOfString("uuid:") != nil) ? usnComponents[0] : nil
    }
    
    class func urn(#usn: String) -> String? {
        let usnComponents = usn.componentsSeparatedByString("::")
        return (usnComponents.count >= 2 && usnComponents[1].rangeOfString("urn:") != nil) ? usnComponents[1] : nil
    }
    
    class func isRootDevice(#usn: String) -> Bool {
        let usnComponents = usn.componentsSeparatedByString("::")
        return usnComponents.count >= 2 && usnComponents[1].rangeOfString("upnp:rootdevice") != nil
    }
}

extension UniqueServiceName: Printable {
    public var description: String {
        return rawValue
    }
}

extension UniqueServiceName: Hashable {
    public var hashValue: Int {
        return rawValue.hashValue
    }
}

public func ==(lhs: UniqueServiceName, rhs: UniqueServiceName) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
