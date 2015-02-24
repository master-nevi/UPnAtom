//
//  ContentDirectory1Service.swift
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

public class ContentDirectory1Service: AbstractUPnPService {
    let sessionManager: SOAPSessionManager!
    
    override init?(ssdpDevice: SSDPDBDevice_ObjC) {
        super.init(ssdpDevice: ssdpDevice)
        
        sessionManager = SOAPSessionManager(baseURL: baseURL, sessionConfiguration: nil)
    }
    
    public func getSortCapabilities(success: (sortCapabilities: String?) -> Void, failure:(error: NSError?) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetSortCapabilities", serviceURN: urn, arguments: nil)
        
        sessionManager.POST(controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(sortCapabilities: responseObject?["SortCaps"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func browse(objectID: String, browseFlag: String, filter: String, startingIndex: String, requestedCount: String, sortCriteria: String, success: (result: String?, numberReturned: String?, totalMatches: String?, updateID: String?) -> Void, failure: (error: NSError?) -> Void) {
        let arguments = [
            "ObjectID" : objectID,
            "BrowseFlag" : browseFlag,
            "Filter": filter,
            "StartingIndex" : startingIndex,
            "RequestedCount" : requestedCount,
            "SortCriteria" : sortCriteria]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Browse", serviceURN: urn, arguments: arguments)
        
        sessionManager.POST(controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(result: responseObject?["Result"], numberReturned: responseObject?["NumberReturned"], totalMatches: responseObject?["TotalMatches"], updateID: responseObject?["UpdateID"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
}

extension ContentDirectory1Service: ExtendedPrintable {
    override public var className: String { return "ContentDirectory1Service" }
    override public var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
