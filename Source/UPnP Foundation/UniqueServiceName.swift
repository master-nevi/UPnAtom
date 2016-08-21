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

/// TODO: For now rooting to NSObject to expose to Objective-C, see Github issue #16
public class UniqueServiceName: NSObject, RawRepresentable {
    public let rawValue: RawValue
    public let uuid: String
    public let urn: String?
    public let rootDevice: Bool
    
    public typealias RawValue = String
    
    public required init?(rawValue: RawValue) {
        self.rawValue = rawValue
        
        // all forms of usn should contain a uuid, otherwise it's invalid and nil will be returned
        guard let uuid = UniqueServiceName.uuid(usn: rawValue) where !uuid.isEmpty else {
            /// TODO: Remove default initializations to simply return nil, see Github issue #11
            self.uuid = ""
            self.rootDevice = false
            self.urn = nil
            super.init()
            return nil
        }
        
        self.uuid = uuid
        
        rootDevice = UniqueServiceName.isRootDevice(usn: rawValue)
        urn = UniqueServiceName.urn(usn: rawValue)
        super.init()
    }
    
    convenience public init?(uuid: String, urn: String) {
        self.init(rawValue: "\(uuid)::\(urn)")
    }
    
    convenience public init?(uuid: String, rootDevice: Bool) {
        let rawValue = rootDevice ? "\(uuid)::upnp:rootdevice" : "\(uuid)"
        self.init(rawValue: rawValue)
    }
    
    class func uuid(usn usn: String) -> String? {
        let usnComponents = usn.componentsSeparatedByString("::")
        return (usnComponents.count >= 1 && usnComponents[0].rangeOfString("uuid:") != nil) ? usnComponents[0] : nil
    }
    
    class func urn(usn usn: String) -> String? {
        let usnComponents = usn.componentsSeparatedByString("::")
        return (usnComponents.count >= 2 && usnComponents[1].rangeOfString("urn:") != nil) ? usnComponents[1] : nil
    }
    
    class func isRootDevice(usn usn: String) -> Bool {
        let usnComponents = usn.componentsSeparatedByString("::")
        return usnComponents.count >= 2 && usnComponents[1].rangeOfString("upnp:rootdevice") != nil
    }
}

extension UniqueServiceName {
    override public var description: String {
        return rawValue
    }
}

extension UniqueServiceName {
    override public var hashValue: Int {
        return rawValue.hashValue
    }
    
    /// Because self is rooted to NSObject, for now, usage as a key in a dictionary will be treated as a key within an NSDictionary; which requires the overriding the methods hash and isEqual, see Github issue #16
    override public var hash: Int {
        return hashValue
    }
    
    /// Because self is rooted to NSObject, for now, usage as a key in a dictionary will be treated as a key within an NSDictionary; which requires the overriding the methods hash and isEqual, see Github issue #16
    override public func isEqual(object: AnyObject?) -> Bool {
        if let other = object as? UniqueServiceName {
            return self == other
        }
        return false
    }
}

public func ==(lhs: UniqueServiceName, rhs: UniqueServiceName) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
