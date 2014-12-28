//
//  ContentDirectory1Service.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/9/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class ContentDirectory1Service_Swift: AbstractUPnPService_Swift {
    let requestSerializer: SOAPRequestSerializer!
    let actionURL: NSURL!
    
    override init?(ssdpDevice: SSDPDBDevice_ObjC) {
        super.init(ssdpDevice: ssdpDevice)
     
        requestSerializer = SOAPRequestSerializer.serializer(urn)
        actionURL = NSURL(string: controlURL.absoluteString!, relativeToURL: baseURL)!
    }
    
    func getSortCapabilities(completion: (sortCapabilities: String?, error: NSError?) -> Void) {
        let soapRequest = prepareSoapRequest("GetSortCapabilities", parameters: nil)
        
        let requestOperation = soapRequest.manager.HTTPRequestOperationWithRequest(soapRequest.request, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            completion(sortCapabilities: responseObject?["SortCaps"], error: nil)
            }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                completion(sortCapabilities: nil, error: error)
        })
        
        soapRequest.manager.operationQueue.addOperation(requestOperation)
    }
    
    func browse(objectID: String, browseFlag: String, filter: String, startingIndex: String, requestedCount: String, sortCriteria: String, completion: (result: String?, numberReturned: String?, totalMatches: String?, updateID: String?, error: NSError?) -> Void) {
        let parameters = [
            "ObjectID" : objectID,
            "BrowseFlag" : browseFlag,
            "Filter": filter,
            "StartingIndex" : startingIndex,
            "RequestedCount" : requestedCount,
            "SortCriteria" : sortCriteria]
        
        let soapRequest = prepareSoapRequest("Browse", parameters: parameters)
        
        let requestOperation = soapRequest.manager.HTTPRequestOperationWithRequest(soapRequest.request, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            completion(result: responseObject?["Result"], numberReturned: responseObject?["NumberReturned"], totalMatches: responseObject?["TotalMatches"], updateID: responseObject?["UpdateID"], error: nil)
            }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                completion(result: nil, numberReturned: nil, totalMatches: nil, updateID: nil, error: error)
        })
        
        soapRequest.manager.operationQueue.addOperation(requestOperation)
    }
    
    private func prepareSoapRequest(soapAction: String, parameters: [String: String]?) -> (request: NSMutableURLRequest, manager: AFHTTPRequestOperationManager) {
        requestSerializer.soapAction = soapAction
        let request = requestSerializer.requestWithMethod("POST", URLString: actionURL.absoluteString, parameters: parameters, error: nil)
        
        let responseSerializer = SOAPResponseSerializer()
        responseSerializer.soapAction = soapAction
        
        let manager = AFHTTPRequestOperationManager()
        manager.responseSerializer = responseSerializer
        
        return (request, manager)
    }
}

extension ContentDirectory1Service_Swift: ExtendedPrintable {
    override var className: String { return "ContentDirectory1Service_Swift" }
    override var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
