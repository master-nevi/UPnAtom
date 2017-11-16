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

open class AVTransport1Event: UPnPEvent {
    open var instanceState = [String: AnyObject]()
    
    override public init(eventXML: Data, service: AbstractUPnPService) {
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
    fileprivate var _instanceState = [String: AnyObject]()
    
    override func parse(document: ONOXMLDocument) -> EmptyResult {
        let result: EmptyResult = .success

        // procedural vs series of nested if let's
        guard let lastChangeXMLString = document.firstChild(withXPath: "/e:propertyset/e:property/LastChange")?.stringValue() else {
            return .failure(createError("No LastChange element in UPnP service event XML"))
        }
        
        LogVerbose("Parsing LastChange XML:\nSTART\n\(lastChangeXMLString)\nEND")
        
        guard let lastChangeEventDocument = try? ONOXMLDocument(string: lastChangeXMLString, encoding: String.Encoding.utf8.rawValue) else {
            return .failure(createError("Unable to parse LastChange XML"))
        }
        
        lastChangeEventDocument.definePrefix("avt", forDefaultNamespace: "urn:schemas-upnp-org:metadata-1-0/AVT/")
        lastChangeEventDocument.enumerateElements(withXPath: "/avt:Event/avt:InstanceID/*", using: { [unowned self] (element: ONOXMLElement!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if let stateValue = element.value(forAttribute: "val") as? String, !stateValue.isEmpty {
                if element.tag.range(of: "MetaData") != nil {
                    guard let metadataDocument = try? ONOXMLDocument(string: stateValue, encoding: String.Encoding.utf8.rawValue) else {
                        return
                    }
                    
                    LogVerbose("Parsing MetaData XML:\nSTART\n\(stateValue)\nEND")
                    
                    var metaData = [String: String]()
                    
                    metadataDocument.definePrefix("didllite", forDefaultNamespace: "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/")
                    metadataDocument.enumerateElements(withXPath: "/didllite:DIDL-Lite/didllite:item/*", using: { (metadataElement: ONOXMLElement!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                        if let elementStringValue = metadataElement.stringValue(), !elementStringValue.isEmpty {
                            metaData[metadataElement.tag] = elementStringValue
                        }
                    } as! (ONOXMLElement?, UInt, UnsafeMutablePointer<ObjCBool>?) -> Void)
                    
                    self._instanceState[element.tag] = metaData as AnyObject
                } else {
                    self._instanceState[element.tag] = stateValue as AnyObject
                }
            }
        } as! (ONOXMLElement?, UInt, UnsafeMutablePointer<ObjCBool>?) -> Void)
        
        return result
    }
    
    func parse(eventXML: Data) -> Result<[String: AnyObject]> {
        switch super.parse(data: eventXML) {
        case .success:
            return .success(_instanceState)
        case .failure(let error):
            return .failure(error)
        }
    }
}
