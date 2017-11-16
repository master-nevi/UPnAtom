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

open class AVTransport1Service: AbstractUPnPService {
    open func setAVTransportURI(instanceID: String, currentURI: String, currentURIMetadata: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "CurrentURI" : currentURI,
            "CurrentURIMetaData": currentURIMetadata]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SetAVTransportURI", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            success()
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func setNextAVTransportURI(instanceID: String, nextURI: String, nextURIMetadata: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "NextURI" : nextURI,
            "NextURIMetaData": nextURIMetadata]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SetNextAVTransportURI", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "SetNextAVTransportURI" is supported
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
    
    open func getMediaInfo(instanceID: String, success: @escaping (_ numberOfTracks: Int, _ mediaDuration: String?, _ currentURI: String?, _ currentURIMetaData: String?, _ nextURI: String?, _ nextURIMetaData: String?, _ playMedium: String?, _ recordMedium: String?, _ writeStatus: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetMediaInfo", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            let responseObject = responseObject as? [String: String]
            var numberOfTracks: Int?
            if let numberOfTracksString = responseObject?["NrTracks"] {
                numberOfTracks = Int(numberOfTracksString)
            }
            
            success(numberOfTracks ?? 0, responseObject?["MediaDuration"], responseObject?["CurrentURI"], responseObject?["CurrentURIMetaData"], responseObject?["NextURI"], responseObject?["NextURIMetaData"], responseObject?["PlayMedium"], responseObject?["RecordMedium"], responseObject?["WriteStatus"])
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func getTransportInfo(instanceID: String, success: @escaping (_ currentTransportState: String?, _ currentTransportStatus: String?, _ currentSpeed: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetTransportInfo", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["CurrentTransportState"], responseObject?["CurrentTransportStatus"], responseObject?["CurrentSpeed"])
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func getPositionInfo(instanceID: String, success: @escaping (_ track: String?, _ trackDuration: String?, _ trackMetaData: String?, _ trackURI: String?, _ relativeTime: String?, _ absoluteTime: String?, _ relativeCount: String?, _ absoluteCount: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetPositionInfo", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["Track"], responseObject?["TrackDuration"], responseObject?["TrackMetaData"], responseObject?["TrackURI"], responseObject?["RelTime"], responseObject?["AbsTime"], responseObject?["RelCount"], responseObject?["AbsCount"])
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func getDeviceCapabilities(instanceID: String, success: @escaping (_ playMedia: String?, _ recordMedia: String?, _ recordQualityModes: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetDeviceCapabilities", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["PlayMedia"], responseObject?["RecMedia"], responseObject?["RecQualityModes"])
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func getTransportSettings(instanceID: String, success: @escaping (_ playMode: String?, _ recordQualityMode: String?) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetTransportSettings", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["PlayMode"], responseObject?["RecQualityMode"])
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func stop(instanceID: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Stop", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            success()
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func play(instanceID: String, speed: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Speed" : speed]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Play", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            success()
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func pause(instanceID: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Pause", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "Pause" is supported
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
    
    open func record(instanceID: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Record", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "Record" is supported
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
    
    open func seek(instanceID: String, unit: String, target: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Unit" : unit,
            "Target" : target]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Seek", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            success()
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func next(instanceID: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Next", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post (controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            success()
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func previous(instanceID: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Previous", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            success()
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func setPlayMode(instanceID: String, newPlayMode: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "NewPlayMode" : newPlayMode]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SetPlayMode", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "SetPlayMode" is supported
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
    
    open func setRecordQualityMode(instanceID: String, newPlayMode: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "NewRecordQualityMode" : newPlayMode]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SetRecordQualityMode", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "SetRecordQualityMode" is supported
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
    
    open func getCurrentTransportActions(instanceID: String, success: @escaping (_ actions: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetCurrentTransportActions", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "GetCurrentTransportActions" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(responseObject?["Actions"])
                }, failure: { (task, error) -> Void in
                    print("having error: \(error)")
                    failure(error as Error)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    override open func createEvent(_ eventXML: Data) -> UPnPEvent {
        return AVTransport1Event(eventXML: eventXML, service: self)
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isAVTransport1Service() -> Bool {
        return self is AVTransport1Service
    }
}

/// overrides ExtendedPrintable protocol implementation
extension AVTransport1Service {
    override public var className: String { return "\(type(of: self))" }
    override open var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
