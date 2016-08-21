//
//  UPnPArchivable.swift
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

public class UPnPArchivable: NSObject, NSCoding {
    public let usn: String
    public let descriptionURL: NSURL
    
    init(usn: String, descriptionURL: NSURL) {
        self.usn = usn
        self.descriptionURL = descriptionURL
    }
    
    required public init?(coder decoder: NSCoder) {
        self.usn = decoder.decodeObjectForKey("usn") as! String
        self.descriptionURL = decoder.decodeObjectForKey("descriptionURL") as! NSURL
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(usn, forKey: "usn")
        coder.encodeObject(descriptionURL, forKey: "descriptionURL")
    }
}

extension AbstractUPnP {
    public func archivable() -> UPnPArchivable {
        return UPnPArchivable(usn: usn.rawValue, descriptionURL: descriptionURL)
    }
}

public class UPnPArchivableAnnex: UPnPArchivable {
    /// Use the custom metadata dictionary to re-populate any missing data fields from a custom device or service subclass. While it's not enforced by the compiler, the contents of the meta data must conform to the NSCoding protocol in order to be archivable. Avoided using Swift generics in order to allow compatability with Obj-C.
    public let customMetadata: [String: AnyObject]
    
    init(usn: String, descriptionURL: NSURL, customMetadata: [String: AnyObject]) {
        self.customMetadata = customMetadata
        super.init(usn: usn, descriptionURL: descriptionURL)
    }
    
    required public init?(coder decoder: NSCoder) {
        self.customMetadata = decoder.decodeObjectForKey("customMetadata") as! [String: AnyObject]
        super.init(coder: decoder)
    }
    
    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder)
        coder.encodeObject(customMetadata, forKey: "customMetadata")
    }
}

extension AbstractUPnP {
    public func archivable(customMetadata customMetadata: [String: AnyObject]) -> UPnPArchivableAnnex {
        return UPnPArchivableAnnex(usn: usn.rawValue, descriptionURL: descriptionURL, customMetadata: customMetadata)
    }
}
