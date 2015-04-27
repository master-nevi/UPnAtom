//
//  ConnectionManager1Service.swift
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

public class ConnectionManager1Service: AbstractUPnPService {
    public func getProtocolInfo(success: (source: [String], sink: [String]) -> Void, failure: (error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetProtocolInfo", serviceURN: urn, arguments: nil)
        
        soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(source: responseObject?["Source"]?.componentsSeparatedByString(",") ?? [String](), sink: responseObject?["Sink"]?.componentsSeparatedByString(",") ?? [String]())
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func prepareForConnection(#remoteProtocolInfo: String, peerConnectionManager: String, peerConnectionID: String, direction: String, success: (connectionID: String?, avTransportID: String?, renderingControlServiceID: String?) -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "RemoteProtocolInfo" : remoteProtocolInfo,
            "PeerConnectionManager" : peerConnectionManager,
            "PeerConnectionID" : peerConnectionID,
            "Direction" : direction]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "PrepareForConnection", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "PrepareForConnection" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(connectionID: responseObject?["ConnectionID"], avTransportID: responseObject?["AVTransportID"], renderingControlServiceID: responseObject?["RcsID"])
                    }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                        failure(error: error)
                })
            }
            else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func connectionComplete(#connectionID: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = ["ConnectionID" : connectionID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "ConnectionComplete", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "ConnectionComplete" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
                    success()
                    }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                        failure(error: error)
                })
            }
            else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func getCurrentConnectionIDs(success: (connectionIDs: [String]) -> Void, failure: (error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetCurrentConnectionIDs", serviceURN: urn, arguments: nil)
        
        soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(connectionIDs: responseObject?["ConnectionIDs"]?.componentsSeparatedByString(",") ?? [String]())
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func getCurrentConnectionInfo(#connectionID: String, success: (renderingControlServiceID: String?, avTransportID: String?, protocolInfo: String?, peerConnectionManager: String?, peerConnectionID: String?, direction: String?, status: String?) -> Void, failure: (error: NSError) -> Void) {
        let arguments = ["ConnectionID" : connectionID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetCurrentConnectionInfo", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(renderingControlServiceID: responseObject?["RcsID"], avTransportID: responseObject?["AVTransportID"], protocolInfo: responseObject?["ProtocolInfo"], peerConnectionManager: responseObject?["PeerConnectionManager"], peerConnectionID: responseObject?["PeerConnectionID"], direction: responseObject?["Direction"], status: responseObject?["Status"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isConnectionManager1Service() -> Bool {
        return self is ConnectionManager1Service
    }
}

extension ConnectionManager1Service: ExtendedPrintable {
    override public var className: String { return "ConnectionManager1Service" }
    override public var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
