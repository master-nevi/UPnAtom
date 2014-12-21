//
//  SOAPResponseParser.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/20/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class SOAPResponseParser: AbstractXMLParser_Swift {
    private let _responseParameters = [String: String]()
    // TODO: Investigate if the abstract parser supports parsing without needing expectedResponseParameters
    init(supportNamespaces: Bool, soapAction: String, expectedResponseParameters: [String]) {
        super.init(supportNamespaces: supportNamespaces)
        
        for parameter in expectedResponseParameters {
            self.addElementObservation(XMLParserElementObservation_Swift(elementPath: ["Envelope", "Body", "\(soapAction)Response", parameter], didStartParsingElement: nil, didEndParsingElement: nil, foundInnerText: { [unowned self] (elementName, text) -> Void in
                self._responseParameters[elementName] = text
            }))
        }
    }
    
    convenience init(soapAction: String, expectedResponseParameters: [String]) {
        self.init(supportNamespaces: true, soapAction: soapAction, expectedResponseParameters: expectedResponseParameters)
    }
    
    func parse(#soapResponseData: NSData) -> Result<[String: String]> {
        switch super.parse(data: soapResponseData) {
        case .Success, .NoContentSuccess:
            return .Success(_responseParameters)
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
