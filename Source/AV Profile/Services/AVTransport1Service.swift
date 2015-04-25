//
//  AVTransport1Service.swift
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

public class AVTransport1Service: AbstractUPnPService {
    public func setAVTransportURI(#instanceID: String, currentURI: String, currentURIMetadata: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "CurrentURI" : currentURI,
            "CurrentURIMetaData": currentURIMetadata]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SetAVTransportURI", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            success()
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func play(#instanceID: String, speed: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Speed" : speed]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Play", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in            
            success()
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func pause(#instanceID: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Pause", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            success()
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    override public func createEvent(eventXML: NSData) -> UPnPEvent {
        return AVTransport1Event(eventXML: eventXML, service: self)
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isAVTransport1Service() -> Bool {
        return self is AVTransport1Service
    }
}

extension AVTransport1Service: ExtendedPrintable {
    override public var className: String { return "AVTransport1Service" }
    override public var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
