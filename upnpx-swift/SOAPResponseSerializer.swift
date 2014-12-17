//
//  SoapResponseSerializer.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/16/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class SOAPResponseSerializer: AFXMLParserResponseSerializer {
    var expectedResponseParameters: [String]?
    var soapAction = ""
    
    private let xmlParser = AbstractXMLParser_Swift(supportNamespaces: true)
    
    override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
        if !validateResponse(response as NSHTTPURLResponse, data: data, error: error) {
            if error == nil {
                return nil
            }
        }
        
        if self.expectedResponseParameters == nil {
            return nil
        }

        println("\(NSString(data: data, encoding: NSUTF8StringEncoding))")
        var serializationError: NSError?
        var reponseObject: AnyObject!
        let expectedResponseParameters = self.expectedResponseParameters!
        var responseParameters = [String: String]()
        
        xmlParser.clearAllElementObservations()
        for parameter in expectedResponseParameters {
            xmlParser.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["Envelope", "Body", "\(soapAction)Response", parameter], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
                responseParameters[elementName] = text
            }))
        }
        
        if xmlParser.parse(data) == .Failed {
            serializationError = NSError(domain: "upnpx-swift", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse SOAP response"])
        }
        
        reponseObject = responseParameters
        
        if serializationError != nil && error != nil {
            error.memory = serializationError!
        }
        
        return reponseObject
    }
}
