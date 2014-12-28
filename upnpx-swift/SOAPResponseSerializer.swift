//
//  SoapResponseSerializer.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/16/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class SOAPResponseSerializer: AFXMLParserResponseSerializer {
    var soapAction: String?
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
        if !validateResponse(response as NSHTTPURLResponse, data: data, error: error) {
            if error == nil {
                return nil
            }
        }
        
        if soapAction == nil {
            return nil
        }

        var serializationError: NSError?
        var responseObject: AnyObject!
        let xmlParser = SOAPResponseParser(soapAction: soapAction!)
        
        switch xmlParser.parse(soapResponseData: data) {
        case .Success(let value):
            responseObject = value()
        case .Failure(let error):
            serializationError = error
        }
        
        if serializationError != nil && error != nil {
            error.memory = serializationError!
        }
        
        return responseObject
    }
}
