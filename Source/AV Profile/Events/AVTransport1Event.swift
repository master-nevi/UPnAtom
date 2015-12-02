//
//  AVTransport1Event.swift
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

import Ono

public class AVTransport1Event: UPnPEvent {
    public var instanceState = [String: AnyObject]()
    
    override public init(eventXML: NSData, service: AbstractUPnPService) {
        super.init(eventXML: eventXML, service: service)
        
        if let parsedInstanceState = AVTransport1EventParser().parse(eventXML: eventXML).value {
            instanceState = parsedInstanceState
        }
    }
}

/// for objective-c type checking
extension UPnPEvent {
    public func isAVTransport1Event() -> Bool {
        return self is AVTransport1Event
    }
}

class AVTransport1EventParser: AbstractDOMXMLParser {
    private var _instanceState = [String: AnyObject]()
    
    override func parse(document document: ONOXMLDocument) -> EmptyResult {
        let result: EmptyResult = .Success

        // procedural vs series of nested if let's
        guard let lastChangeXMLString = document.firstChildWithXPath("/e:propertyset/e:property/LastChange")?.stringValue() else {
            return .Failure(createError("No LastChange element in UPnP service event XML"))
        }
        
        LogVerbose("Parsing LastChange XML:\nSTART\n\(lastChangeXMLString)\nEND")
        
        guard let lastChangeEventDocument = try? ONOXMLDocument(string: lastChangeXMLString, encoding: NSUTF8StringEncoding) else {
            return .Failure(createError("Unable to parse LastChange XML"))
        }
        
        lastChangeEventDocument.definePrefix("avt", forDefaultNamespace: "urn:schemas-upnp-org:metadata-1-0/AVT/")
        lastChangeEventDocument.enumerateElementsWithXPath("/avt:Event/avt:InstanceID/*", usingBlock: { [unowned self] (element: ONOXMLElement!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if let stateValue = element.valueForAttribute("val") as? String where !stateValue.isEmpty {
                if element.tag.rangeOfString("MetaData") != nil {
                    guard let metadataDocument = try? ONOXMLDocument(string: stateValue, encoding: NSUTF8StringEncoding) else {
                        return
                    }
                    
                    LogVerbose("Parsing MetaData XML:\nSTART\n\(stateValue)\nEND")
                    
                    var metaData = [String: String]()
                    
                    metadataDocument.definePrefix("didllite", forDefaultNamespace: "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/")
                    metadataDocument.enumerateElementsWithXPath("/didllite:DIDL-Lite/didllite:item/*", usingBlock: { (metadataElement: ONOXMLElement!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                        if let elementStringValue = metadataElement.stringValue() where !elementStringValue.isEmpty {
                            metaData[metadataElement.tag] = elementStringValue
                        }
                    })
                    
                    self._instanceState[element.tag] = metaData
                }
                else {
                    self._instanceState[element.tag] = stateValue
                }
            }
        })
        
        return result
    }
    
    func parse(eventXML eventXML: NSData) -> Result<[String: AnyObject]> {
        switch super.parse(data: eventXML) {
        case .Success:
            return .Success(RVW(_instanceState))
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
