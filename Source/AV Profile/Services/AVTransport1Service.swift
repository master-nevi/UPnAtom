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
    
    public func setNextAVTransportURI(#instanceID: String, nextURI: String, nextURIMetadata: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "NextURI" : nextURI,
            "NextURIMetaData": nextURIMetadata]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SetNextAVTransportURI", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "SetNextAVTransportURI" is supported
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
    
    public func getMediaInfo(#instanceID: String, success: (numberOfTracks: Int, mediaDuration: String?, currentURI: String?, currentURIMetaData: String?, nextURI: String?, nextURIMetaData: String?, playMedium: String?, recordMedium: String?, writeStatus: String?) -> Void, failure: (error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetMediaInfo", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(numberOfTracks: responseObject?["NrTracks"]?.toInt() ?? 0, mediaDuration: responseObject?["MediaDuration"], currentURI: responseObject?["CurrentURI"], currentURIMetaData: responseObject?["CurrentURIMetaData"], nextURI: responseObject?["NextURI"], nextURIMetaData: responseObject?["NextURIMetaData"], playMedium: responseObject?["PlayMedium"], recordMedium: responseObject?["RecordMedium"], writeStatus: responseObject?["WriteStatus"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func getTransportInfo(#instanceID: String, success: (currentTransportState: String?, currentTransportStatus: String?, currentSpeed: String?) -> Void, failure: (error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetTransportInfo", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(currentTransportState: responseObject?["CurrentTransportState"], currentTransportStatus: responseObject?["CurrentTransportStatus"], currentSpeed: responseObject?["CurrentSpeed"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func getPositionInfo(#instanceID: String, success: (track: String?, trackDuration: String?, trackMetaData: String?, trackURI: String?, relativeTime: String?, absoluteTime: String?, relativeCount: String?, absoluteCount: String?) -> Void, failure: (error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetPositionInfo", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(track: responseObject?["Track"], trackDuration: responseObject?["TrackDuration"], trackMetaData: responseObject?["TrackMetaData"], trackURI: responseObject?["TrackURI"], relativeTime: responseObject?["RelTime"], absoluteTime: responseObject?["AbsTime"], relativeCount: responseObject?["RelCount"], absoluteCount: responseObject?["AbsCount"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func getDeviceCapabilities(#instanceID: String, success: (playMedia: String?, recordMedia: String?, recordQualityModes: String?) -> Void, failure: (error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetDeviceCapabilities", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(playMedia: responseObject?["PlayMedia"], recordMedia: responseObject?["RecMedia"], recordQualityModes: responseObject?["RecQualityModes"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func getTransportSettings(#instanceID: String, success: (playMode: String?, recordQualityMode: String?) -> Void, failure: (error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetTransportSettings", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(self.controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(playMode: responseObject?["PlayMode"], recordQualityMode: responseObject?["RecQualityMode"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func stop(#instanceID: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Stop", serviceURN: urn, arguments: arguments)
        
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
        
        // Check if the optional SOAP action "Pause" is supported
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

    public func record(#instanceID: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Record", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "Record" is supported
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
