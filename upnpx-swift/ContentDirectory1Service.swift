//
//  ContentDirectory1Service.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/9/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class ContentDirectory1Service: AbstractUPnPService {
    let sessionManager: SOAPSessionManager!
    
    override init?(ssdpDevice: SSDPDBDevice_ObjC) {
        super.init(ssdpDevice: ssdpDevice)
        
        sessionManager = SOAPSessionManager(baseURL: baseURL)
    }
    
    func getSortCapabilities(success: (sortCapabilities: String?) -> Void, failure:(error: NSError?) -> Void) {
        let parameters = SOAPRequestParameters(soapAction: "GetSortCapabilities", serviceURN: urn, arguments: nil)
        
        sessionManager.POST(controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(sortCapabilities: responseObject?["SortCaps"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    func browse(objectID: String, browseFlag: String, filter: String, startingIndex: String, requestedCount: String, sortCriteria: String, success: (result: String?, numberReturned: String?, totalMatches: String?, updateID: String?) -> Void, failure: (error: NSError?) -> Void) {
        let arguments = [
            "ObjectID" : objectID,
            "BrowseFlag" : browseFlag,
            "Filter": filter,
            "StartingIndex" : startingIndex,
            "RequestedCount" : requestedCount,
            "SortCriteria" : sortCriteria]
        
        let parameters = SOAPRequestParameters(soapAction: "Browse", serviceURN: urn, arguments: arguments)
        
        sessionManager.POST(controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(result: responseObject?["Result"], numberReturned: responseObject?["NumberReturned"], totalMatches: responseObject?["TotalMatches"], updateID: responseObject?["UpdateID"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
}

extension ContentDirectory1Service: ExtendedPrintable {
    override var className: String { return "ContentDirectory1Service" }
    override var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
