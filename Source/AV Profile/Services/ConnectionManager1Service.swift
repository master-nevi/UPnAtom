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

open class ConnectionManager1Service: AbstractUPnPService {
    open func getProtocolInfo(_ success: @escaping (_ source: [String], _ sink: [String]) -> Void, failure: @escaping (_ error: Error) -> Void) {
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetProtocolInfo", serviceURN: urn, arguments: nil)
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) in
            let responseObject = responseObject as? [String: String]
            if let sourceValue = responseObject?["Source"] as? String, let sinkValue = responseObject?["Sink"] as? String {
                success(sourceValue.components(separatedBy: ",") ?? [String](), sinkValue.components(separatedBy: ",") ?? [String]())
            }
        }, failure: { (task, error) in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func prepareForConnection(remoteProtocolInfo: String, peerConnectionManager: String, peerConnectionID: String, direction: String, success: @escaping (_ connectionID: String?, _ avTransportID: String?, _ renderingControlServiceID: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "RemoteProtocolInfo" : remoteProtocolInfo,
            "PeerConnectionManager" : peerConnectionManager,
            "PeerConnectionID" : peerConnectionID,
            "Direction" : direction]
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "PrepareForConnection", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "PrepareForConnection" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(responseObject?["ConnectionID"], responseObject?["AVTransportID"], responseObject?["RcsID"])
                    }, failure: { (task, error) -> Void in
                        print("having error: \(error)")
                        failure(error as Error)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    open func connectionComplete(connectionID: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["ConnectionID" : connectionID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "ConnectionComplete", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "ConnectionComplete" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
                    success()
                    }, failure: { (task, error) -> Void in
                        print("having error: \(error)")
                        failure(error as Error)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    open func getCurrentConnectionIDs(_ success: @escaping (_ connectionIDs: [String]) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetCurrentConnectionIDs", serviceURN: urn, arguments: nil)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            let responseObject = responseObject as? [String: String]
            if let connectionIDsValue = responseObject?["ConnectionIDs"] as? String {
                success(connectionIDsValue.components(separatedBy: ",") ?? [String]())
            }
        } , failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func getCurrentConnectionInfo(connectionID: String, success: @escaping (_ renderingControlServiceID: String?, _ avTransportID: String?, _ protocolInfo: String?, _ peerConnectionManager: String?, _ peerConnectionID: String?, _ direction: String?, _ status: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = ["ConnectionID" : connectionID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetCurrentConnectionInfo", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["RcsID"], responseObject?["AVTransportID"], responseObject?["ProtocolInfo"], responseObject?["PeerConnectionManager"], responseObject?["PeerConnectionID"], responseObject?["Direction"], responseObject?["Status"])
            }, failure: { (task, error) -> Void in
                print("having error: \(error)")
                failure(error as Error)
        })
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isConnectionManager1Service() -> Bool {
        return self is ConnectionManager1Service
    }
}

/// overrides ExtendedPrintable protocol implementation
extension ConnectionManager1Service {
    override public var className: String { return "\(type(of: self))" }
    override open var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
