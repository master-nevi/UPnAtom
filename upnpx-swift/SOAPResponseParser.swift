//
//  SOAPResponseParser.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/20/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class SOAPResponseParser: AbstractXMLParser_Swift {
    private var _responseParameters = [String: String]()
    
    init(supportNamespaces: Bool, soapAction: String) {
        super.init(supportNamespaces: supportNamespaces)
        self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["Envelope", "Body", "\(soapAction)Response", "*"], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
            self._responseParameters[elementName] = text
        }))
    }
    
    convenience init(soapAction: String) {
        self.init(supportNamespaces: true, soapAction: soapAction)
    }
    
    func parse(#soapResponseData: NSData) -> Result<[String: String]> {
//        println("RESPONSE: \(NSString(data: soapResponseData, encoding: NSUTF8StringEncoding))")
        switch super.parse(data: soapResponseData) {
        case .Success:
            return .Success(_responseParameters)
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
