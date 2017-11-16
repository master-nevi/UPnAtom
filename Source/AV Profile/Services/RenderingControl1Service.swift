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

open class RenderingControl1Service: AbstractUPnPService {
    open func listPresets(instanceID: String, success: @escaping (_ presetNameList: [String]) -> Void, failure: @escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "ListPresets", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            let responseObject = responseObject as? [String: String]
            success(responseObject?["CurrentPresetNameList"]?.components(separatedBy: ",") ?? [String]())
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func selectPreset(instanceID: String, presetName: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "PresetName" : presetName]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SelectPreset", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.post(controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
            success()
        }, failure: { (task, error) -> Void in
            print("having error: \(error)")
            failure(error as Error)
        })
    }
    
    open func getBrightness(instanceID: String, success: @escaping (_ brightness: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Brightness", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setBrightness(instanceID: String, brightness: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Brightness", stateVariableValue: brightness, success: success, failure: failure)
    }
    
    open func getContrast(instanceID: String, success: @escaping (_ contrast: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Contrast", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setContrast(instanceID: String, contrast: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Contrast", stateVariableValue: contrast, success: success, failure: failure)
    }
    
    open func getSharpness(instanceID: String, success: @escaping (_ sharpness: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Sharpness", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setSharpness(instanceID: String, sharpness: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Sharpness", stateVariableValue: sharpness, success: success, failure: failure)
    }
    
    open func getRedVideoGain(instanceID: String, success: @escaping (_ redVideoGain: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "RedVideoGain", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setRedVideoGain(instanceID: String, redVideoGain: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "RedVideoGain", stateVariableValue: redVideoGain, success: success, failure: failure)
    }
    
    open func getGreenVideoGain(instanceID: String, success: @escaping (_ greenVideoGain: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "GreenVideoGain", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setGreenVideoGain(instanceID: String, greenVideoGain: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "GreenVideoGain", stateVariableValue: greenVideoGain, success: success, failure: failure)
    }
    
    open func getBlueVideoGain(instanceID: String, success: @escaping (_ blueVideoGain: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "BlueVideoGain", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setBlueVideoGain(instanceID: String, blueVideoGain: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "BlueVideoGain", stateVariableValue: blueVideoGain, success: success, failure: failure)
    }
    
    open func getRedVideoBlackLevel(instanceID: String, success: @escaping (_ redVideoBlackLevel: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "RedVideoBlackLevel", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setRedVideoBlackLevel(instanceID: String, redVideoBlackLevel: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "RedVideoBlackLevel", stateVariableValue: redVideoBlackLevel, success: success, failure: failure)
    }
    
    open func getGreenVideoBlackLevel(instanceID: String, success: @escaping (_ greenVideoBlackLevel: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "GreenVideoBlackLevel", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setGreenVideoBlackLevel(instanceID: String, greenVideoBlackLevel: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "GreenVideoBlackLevel", stateVariableValue: greenVideoBlackLevel, success: success, failure: failure)
    }
    
    open func getBlueVideoBlackLevel(instanceID: String, success: @escaping (_ blueVideoBlackLevel: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "BlueVideoBlackLevel", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setBlueVideoBlackLevel(instanceID: String, blueVideoBlackLevel: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "BlueVideoBlackLevel", stateVariableValue: blueVideoBlackLevel, success: success, failure: failure)
    }
    
    open func getColorTemperature(instanceID: String, success: @escaping (_ colorTemperature: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "ColorTemperature", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setColorTemperature(instanceID: String, colorTemperature: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "ColorTemperature", stateVariableValue: colorTemperature, success: success, failure: failure)
    }
    
    open func getHorizontalKeystone(instanceID: String, success: @escaping (_ horizontalKeystone: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "HorizontalKeystone", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setHorizontalKeystone(instanceID: String, horizontalKeystone: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "HorizontalKeystone", stateVariableValue: horizontalKeystone, success: success, failure: failure)
    }
    
    open func getVerticalKeystone(instanceID: String, success: @escaping (_ verticalKeystone: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "VerticalKeystone", success: { (stateVariableValue: String?) -> Void in
            success(stateVariableValue)
        }, failure: failure)
    }
    
    open func setVerticalKeystone(instanceID: String, verticalKeystone: String, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "VerticalKeystone", stateVariableValue: verticalKeystone, success: success, failure: failure)
    }
    
    open func getMute(instanceID: String, channel: String = "Master", success: @escaping (_ mute: Bool) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Mute", additionalArguments: ["Channel" : channel], isOptional: false, success: { (stateVariableValue: String?) -> Void in
            success((stateVariableValue ?? "0") == "0" ? false : true)
        }, failure: failure)
    }
    
    open func setMute(instanceID: String, mute: Bool, channel: String = "Master", success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Mute", stateVariableValue: mute ? "1" : "0", additionalArguments: ["Channel" : channel], isOptional: false, success: success, failure: failure)
    }
    
    open func getVolume(instanceID: String, channel: String = "Master", success: @escaping (_ volume: Int) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Volume", additionalArguments: ["Channel" : channel], success: { (stateVariableValue: String?) -> Void in
            success(Int(String(describing: stateVariableValue)) ?? 0)
        }, failure: failure)
    }
    
    open func setVolume(instanceID: String, volume: Int, channel: String = "Master", success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Volume", stateVariableValue: "\(volume)", additionalArguments: ["Channel" : channel], success: success, failure: failure)
    }
    
    open func getVolumeDB(instanceID: String, channel: String = "Master", success: @escaping (_ volumeDB: Int) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Channel" : channel]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetVolumeDB", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "GetVolumeDB" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(Int(String(describing: responseObject?["CurrentVolume"])) ?? 0)
                }, failure: { (task, error) -> Void in
                    print("having error: \(error)")
                    failure(error as Error)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    open func setVolumeDB(instanceID: String, volumeDB: Int, channel: String = "Master", success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Channel" : channel,
            "DesiredVolume" : "\(volumeDB)"]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "SetVolumeDB", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "SetVolumeDB" is supported
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
    
    open func getVolumeDBRange(instanceID: String, channel: String = "Master", success: @escaping (_ minimumValue: Int, _ maximumValue: Int) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Channel" : channel]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetVolumeDBRange", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "getVolumeDBRange" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(Int(String(describing: responseObject?["MinValue"])) ?? 0, Int(String(describing: responseObject?["MaxValue"])) ?? 0)
                }, failure: { (task, error) -> Void in
                    print("having error: \(error)")
                    failure(error as Error)
                })
            } else {
                failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    open func getLoudness(instanceID: String, channel: String = "Master", success: @escaping (_ loudness: Bool) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        getStateVariable(instanceID: instanceID, stateVariableName: "Loudness", additionalArguments: ["Channel" : channel], isOptional: false, success: { (stateVariableValue: String?) -> Void in
            success((stateVariableValue ?? "0") == "0" ? false : true)
        }, failure: failure)
    }
    
    open func setLoudness(instanceID: String, loudness: Bool, channel: String = "Master", success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        setStateVariable(instanceID: instanceID, stateVariableName: "Loudness", stateVariableValue: loudness ? "1" : "0", additionalArguments: ["Channel" : channel], isOptional: false, success: success, failure: failure)
    }
    
    fileprivate func getStateVariable(instanceID: String, stateVariableName: String, additionalArguments: [String: String] = [String: String](), isOptional: Bool = true, success: @escaping (_ stateVariableValue: String?) -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = ["InstanceID" : instanceID] + additionalArguments
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Get\(stateVariableName)", serviceURN: urn, arguments: arguments)
        
        let performAction = { () -> Void in
            self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
                let responseObject = responseObject as? [String: String]
                success(responseObject?["Current\(stateVariableName)"])
            }, failure: { (task, error) -> Void in
                print("having error: \(error)")
                failure(error as Error)
            })
        }
        
        if isOptional {
            // Check if the optional SOAP action "Get<stateVariableName>" is supported
            supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
                if isSupported {
                    performAction()
                } else {
                    failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
                }
            }
        } else {
            performAction()
        }
    }
    
    fileprivate func setStateVariable(instanceID: String, stateVariableName: String, stateVariableValue: String, additionalArguments: [String: String] = [String: String](), isOptional: Bool = true, success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        let arguments = [
            "InstanceID" : instanceID,
            "Desired\(stateVariableName)" : stateVariableValue] +
        additionalArguments
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Set\(stateVariableName)", serviceURN: urn, arguments: arguments)
        
        let performAction = { () -> Void in
            self.soapSessionManager.post(self.controlURL.absoluteString, parameters: parameters, success: { (task, responseObject) -> Void in
                success()
            }, failure: {(task, error) -> Void in
                print("having error: \(error)")
                failure(error as Error)
            })
        }
        
        if isOptional {
            // Check if the optional SOAP action "Set<stateVariableName>" is supported
            supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
                if isSupported {
                    performAction()
                } else {
                    failure(createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
                }
            }
        } else {
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
    override public var className: String { return "\(type(of: self))" }
    override open var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
