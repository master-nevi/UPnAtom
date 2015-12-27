//
//  RenderingControl1Service.swift
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

public class RenderingControl1Service: AbstractUPnPService {
    public func listPresets(instanceID instanceID: String, success: (presetNameList: [String]) -> Void, failure: (error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "ListPresets", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(presetNameList: responseObject?["CurrentPresetNameList"]?.componentsSeparatedByString(",") ?? [String]())
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func selectPreset(instanceID instanceID: String, presetName: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "PresetName" : presetName]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SelectPreset", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            success()
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func getBrightness(instanceID instanceID: String, success: (brightness: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Brightness", success: { (stateVariableValue: String?) -> Void in
            success(brightness: stateVariableValue)
        }, failure: failure)
    }
    
    public func setBrightness(instanceID instanceID: String, brightness: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Brightness", stateVariableValue: brightness, success: success, failure: failure)
    }
    
    public func getContrast(instanceID instanceID: String, success: (contrast: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Contrast", success: { (stateVariableValue: String?) -> Void in
            success(contrast: stateVariableValue)
            }, failure: failure)
    }
    
    public func setContrast(instanceID instanceID: String, contrast: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Contrast", stateVariableValue: contrast, success: success, failure: failure)
    }
    
    public func getSharpness(instanceID instanceID: String, success: (sharpness: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Sharpness", success: { (stateVariableValue: String?) -> Void in
            success(sharpness: stateVariableValue)
            }, failure: failure)
    }
    
    public func setSharpness(instanceID instanceID: String, sharpness: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Sharpness", stateVariableValue: sharpness, success: success, failure: failure)
    }
    
    public func getRedVideoGain(instanceID instanceID: String, success: (redVideoGain: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "RedVideoGain", success: { (stateVariableValue: String?) -> Void in
            success(redVideoGain: stateVariableValue)
            }, failure: failure)
    }
    
    public func setRedVideoGain(instanceID instanceID: String, redVideoGain: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "RedVideoGain", stateVariableValue: redVideoGain, success: success, failure: failure)
    }
    
    public func getGreenVideoGain(instanceID instanceID: String, success: (greenVideoGain: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "GreenVideoGain", success: { (stateVariableValue: String?) -> Void in
            success(greenVideoGain: stateVariableValue)
            }, failure: failure)
    }
    
    public func setGreenVideoGain(instanceID instanceID: String, greenVideoGain: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "GreenVideoGain", stateVariableValue: greenVideoGain, success: success, failure: failure)
    }
    
    public func getBlueVideoGain(instanceID instanceID: String, success: (blueVideoGain: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "BlueVideoGain", success: { (stateVariableValue: String?) -> Void in
            success(blueVideoGain: stateVariableValue)
            }, failure: failure)
    }
    
    public func setBlueVideoGain(instanceID instanceID: String, blueVideoGain: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "BlueVideoGain", stateVariableValue: blueVideoGain, success: success, failure: failure)
    }
    
    public func getRedVideoBlackLevel(instanceID instanceID: String, success: (redVideoBlackLevel: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "RedVideoBlackLevel", success: { (stateVariableValue: String?) -> Void in
            success(redVideoBlackLevel: stateVariableValue)
            }, failure: failure)
    }
    
    public func setRedVideoBlackLevel(instanceID instanceID: String, redVideoBlackLevel: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "RedVideoBlackLevel", stateVariableValue: redVideoBlackLevel, success: success, failure: failure)
    }
    
    public func getGreenVideoBlackLevel(instanceID instanceID: String, success: (greenVideoBlackLevel: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "GreenVideoBlackLevel", success: { (stateVariableValue: String?) -> Void in
            success(greenVideoBlackLevel: stateVariableValue)
            }, failure: failure)
    }
    
    public func setGreenVideoBlackLevel(instanceID instanceID: String, greenVideoBlackLevel: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "GreenVideoBlackLevel", stateVariableValue: greenVideoBlackLevel, success: success, failure: failure)
    }
    
    public func getBlueVideoBlackLevel(instanceID instanceID: String, success: (blueVideoBlackLevel: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "BlueVideoBlackLevel", success: { (stateVariableValue: String?) -> Void in
            success(blueVideoBlackLevel: stateVariableValue)
            }, failure: failure)
    }
    
    public func setBlueVideoBlackLevel(instanceID instanceID: String, blueVideoBlackLevel: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "BlueVideoBlackLevel", stateVariableValue: blueVideoBlackLevel, success: success, failure: failure)
    }
    
    public func getColorTemperature(instanceID instanceID: String, success: (colorTemperature: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "ColorTemperature", success: { (stateVariableValue: String?) -> Void in
            success(colorTemperature: stateVariableValue)
            }, failure: failure)
    }
    
    public func setColorTemperature(instanceID instanceID: String, colorTemperature: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "ColorTemperature", stateVariableValue: colorTemperature, success: success, failure: failure)
    }
    
    public func getHorizontalKeystone(instanceID instanceID: String, success: (horizontalKeystone: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "HorizontalKeystone", success: { (stateVariableValue: String?) -> Void in
            success(horizontalKeystone: stateVariableValue)
            }, failure: failure)
    }
    
    public func setHorizontalKeystone(instanceID instanceID: String, horizontalKeystone: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "HorizontalKeystone", stateVariableValue: horizontalKeystone, success: success, failure: failure)
    }
    
    public func getVerticalKeystone(instanceID instanceID: String, success: (verticalKeystone: String?) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "VerticalKeystone", success: { (stateVariableValue: String?) -> Void in
            success(verticalKeystone: stateVariableValue)
            }, failure: failure)
    }
    
    public func setVerticalKeystone(instanceID instanceID: String, verticalKeystone: String, success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "VerticalKeystone", stateVariableValue: verticalKeystone, success: success, failure: failure)
    }
    
    public func getMute(instanceID instanceID: String, channel: String = "Master", success: (mute: Bool) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Mute", additionalArguments: ["Channel" : channel], isOptional: false, success: { (stateVariableValue: String?) -> Void in
            success(mute: (stateVariableValue ?? "0") == "0" ? false : true)
            }, failure: failure)
    }
    
    public func setMute(instanceID instanceID: String, mute: Bool, channel: String = "Master", success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Mute", stateVariableValue: mute ? "1" : "0", additionalArguments: ["Channel" : channel], isOptional: false, success: success, failure: failure)
    }
    
    public func getVolume(instanceID instanceID: String, channel: String = "Master", success: (volume: Int) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Volume", additionalArguments: ["Channel" : channel], success: { (stateVariableValue: String?) -> Void in
            success(volume: Int(String(stateVariableValue)) ?? 0)
            }, failure: failure)
    }
    
    public func setVolume(instanceID instanceID: String, volume: Int, channel: String = "Master", success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Volume", stateVariableValue: "\(volume)", additionalArguments: ["Channel" : channel], success: success, failure: failure)
    }
    
    public func getVolumeDB(instanceID instanceID: String, channel: String = "Master", success: (volumeDB: Int) -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Channel" : channel]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetVolumeDB", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "GetVolumeDB" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(volumeDB: Int(String(responseObject?["CurrentVolume"])) ?? 0)
                    }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                        failure(error: error)
                })
            }
            else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func setVolumeDB(instanceID instanceID: String, volumeDB: Int, channel: String = "Master", success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Channel" : channel,
            "DesiredVolume" : "\(volumeDB)"]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SetVolumeDB", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "SetVolumeDB" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
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
    
    public func getVolumeDBRange(instanceID instanceID: String, channel: String = "Master", success: (minimumValue: Int, maximumValue: Int) -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Channel" : channel]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetVolumeDBRange", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "getVolumeDBRange" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(minimumValue: Int(String(responseObject?["MinValue"])) ?? 0, maximumValue: Int(String(responseObject?["MaxValue"])) ?? 0)
                    }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                        failure(error: error)
                })
            }
            else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func getLoudness(instanceID instanceID: String, channel: String = "Master", success: (loudness: Bool) -> Void, failure:(error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Loudness", additionalArguments: ["Channel" : channel], isOptional: false, success: { (stateVariableValue: String?) -> Void in
            success(loudness: (stateVariableValue ?? "0") == "0" ? false : true)
            }, failure: failure)
    }
    
    public func setLoudness(instanceID instanceID: String, loudness: Bool, channel: String = "Master", success: () -> Void, failure:(error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Loudness", stateVariableValue: loudness ? "1" : "0", additionalArguments: ["Channel" : channel], isOptional: false, success: success, failure: failure)
    }
    
    private func getStateVariable(instanceID instanceID: String, stateVariableName: String, additionalArguments: [String: String] = [String: String](), isOptional: Bool = true, success: (stateVariableValue: String?) -> Void, failure:(error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID] + additionalArguments
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Get\(stateVariableName)", serviceURN: urn, arguments: arguments)
        
        let performAction = { () -> Void in
            self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
                let responseObject = responseObject as? [String: String]
                success(stateVariableValue: responseObject?["Current\(stateVariableName)"])
                }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                    failure(error: error)
            })
        }
        
        if isOptional {
            // Check if the optional SOAP action "Get<stateVariableName>" is supported
            supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
                if isSupported {
                    performAction()
                }
                else {
                    failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
                }
            }
        }
        else {
            performAction()
        }
    }
    
    private func setStateVariable(instanceID instanceID: String, stateVariableName: String, stateVariableValue: String, additionalArguments: [String: String] = [String: String](), isOptional: Bool = true, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Desired\(stateVariableName)" : stateVariableValue] +
        additionalArguments
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Set\(stateVariableName)", serviceURN: urn, arguments: arguments)
        
        let performAction = { () -> Void in
            self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
                success()
                }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                    failure(error: error)
            })
        }
        
        if isOptional {
            // Check if the optional SOAP action "Set<stateVariableName>" is supported
            supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
                if isSupported {
                    performAction()
                }
                else {
                    failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
                }
            }
        }
        else {
            performAction()
        }
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isRenderingControl1Service() -> Bool {
        return self is RenderingControl1Service
    }
}

/// overrides ExtendedPrintable protocol implementations
extension RenderingControl1Service {
    override public var className: String { return "RenderingControl1Service" }
    override public var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
