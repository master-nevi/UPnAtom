//
//  ContentDirectory1Service.swift
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
import Ono

public class ContentDirectory1Service: AbstractUPnPService {
    public func getSearchCapabilities(success: (searchCapabilities: String?) -> Void, failure:(error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetSearchCapabilities", serviceURN: urn, arguments: nil)
        
        soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            let responseObject = responseObject as? [String: String]
            success(searchCapabilities: responseObject?["SearchCaps"])
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                failure(error: error)
        })
    }
    
    public func getSortCapabilities(success: (sortCapabilities: String?) -> Void, failure:(error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetSortCapabilities", serviceURN: urn, arguments: nil)
        
        soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            let responseObject = responseObject as? [String: String]
            success(sortCapabilities: responseObject?["SortCaps"])
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                failure(error: error)
        })
    }
    
    public func getSystemUpdateID(success: (systemUpdateID: String?) -> Void, failure:(error: NSError) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetSystemUpdateID", serviceURN: urn, arguments: nil)
        
        soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            let responseObject = responseObject as? [String: String]
            success(systemUpdateID: responseObject?["Id"])
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                failure(error: error)
        })
    }
    
    public func browse(objectID objectID: String, browseFlag: String, filter: String, startingIndex: String, requestedCount: String, sortCriteria: String, success: (result: [ContentDirectory1Object], numberReturned: Int, totalMatches: Int, updateID: String?) -> Void, failure: (error: NSError) -> Void) {
        let arguments = [
            "ObjectID" : objectID,
            "BrowseFlag" : browseFlag,
            "Filter": filter,
            "StartingIndex" : startingIndex,
            "RequestedCount" : requestedCount,
            "SortCriteria" : sortCriteria]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Browse", serviceURN: urn, arguments: arguments)
        
        soapSessionManager.POST(controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                let responseObject = responseObject as? [String: String]
                
                var result = [ContentDirectory1Object]()
                if let resultString = responseObject?["Result"],
                    parserResult = ContentDirectoryBrowseResultParser().parse(browseResultData: resultString.dataUsingEncoding(NSUTF8StringEncoding)!).value {
                        result = parserResult
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in                    
                    success(result: result, numberReturned: Int(String(responseObject?["NumberReturned"])) ?? 0, totalMatches: Int(String(responseObject?["TotalMatches"])) ?? 0, updateID: responseObject?["UpdateID"])
                })
            })
            }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                failure(error: error)
        })
    }
    
    public func search(containerID containerID: String, searchCriteria: String, filter: String, startingIndex: String, requestedCount: String, sortCriteria: String, success: (result: [ContentDirectory1Object], numberReturned: Int, totalMatches: Int, updateID: String?) -> Void, failure: (error: NSError) -> Void) {
        let arguments = [
            "ContainerID" : containerID,
            "SearchCriteria" : searchCriteria,
            "Filter": filter,
            "StartingIndex" : startingIndex,
            "RequestedCount" : requestedCount,
            "SortCriteria" : sortCriteria]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Search", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "Search" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        let responseObject = responseObject as? [String: String]
                        
                        var result = [ContentDirectory1Object]()
                        if let resultString = responseObject?["Result"],
                            parserResult = ContentDirectoryBrowseResultParser().parse(browseResultData: resultString.dataUsingEncoding(NSUTF8StringEncoding)!).value {
                                result = parserResult
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            success(result: result, numberReturned: Int(String(responseObject?["NumberReturned"])) ?? 0, totalMatches: Int(String(responseObject?["TotalMatches"])) ?? 0, updateID: responseObject?["UpdateID"])
                        })
                    })
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func createObject(containerID containerID: String, elements: String, success: (objectID: String?, result: [ContentDirectory1Object]) -> Void, failure: (error: NSError) -> Void) {
        let arguments = [
            "ContainerID" : containerID,
            "Elements" : elements]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "CreateObject", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "CreateObject" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                        let responseObject = responseObject as? [String: String]
                        
                        var result = [ContentDirectory1Object]()
                        if let resultString = responseObject?["Result"],
                            parserResult = ContentDirectoryBrowseResultParser().parse(browseResultData: resultString.dataUsingEncoding(NSUTF8StringEncoding)!).value {
                                result = parserResult
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            success(objectID: responseObject?["ObjectID"], result: result)
                        })
                    })
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func destroyObject(objectID objectID: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = ["ObjectID" : objectID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "DestroyObject", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "DestroyObject" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    success()
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func updateObject(objectID objectID: String, currentTagValue: String, newTagValue: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "ObjectID" : objectID,
            "CurrentTagValue" : currentTagValue,
            "NewTagValue" : newTagValue]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "UpdateObject", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "UpdateObject" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    success()
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func importResource(sourceURI sourceURI: String, destinationURI: String, success: (transferID: String?) -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "SourceURI" : sourceURI,
            "DestinationURI" : destinationURI]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "ImportResource", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "ImportResource" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(transferID: responseObject?["TransferID"])
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func exportResource(sourceURI sourceURI: String, destinationURI: String, success: (transferID: String?) -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "SourceURI" : sourceURI,
            "DestinationURI" : destinationURI]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "ExportResource", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "ExportResource" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(transferID: responseObject?["TransferID"])
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func stopTransferResource(transferID transferID: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = ["TransferID" : transferID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "StopTransferResource", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "StopTransferResource" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    success()
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func getTransferProgress(transferID transferID: String, success: (transferStatus: String?, transferLength: String?, transferTotal: String?) -> Void, failure:(error: NSError) -> Void) {
        let arguments = ["TransferID" : transferID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetTransferProgress", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "GetTransferProgress" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(transferStatus: responseObject?["TransferStatus"], transferLength: responseObject?["TransferLength"], transferTotal: responseObject?["TransferTotal"])
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func deleteResource(resourceURI resourceURI: String, success: () -> Void, failure:(error: NSError) -> Void) {
        let arguments = ["ResourceURI" : resourceURI]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "DeleteResource", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "DeleteResource" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    success()
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
    
    public func createReference(containerID containerID: String, objectID: String, success: (newID: String?) -> Void, failure:(error: NSError) -> Void) {
        let arguments = [
            "ContainerID" : containerID,
            "ObjectID" : objectID]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "CreateReference", serviceURN: urn, arguments: arguments)
        
        // Check if the optional SOAP action "CreateReference" is supported
        supportsSOAPAction(actionParameters: parameters) { (isSupported) -> Void in
            if isSupported {
                self.soapSessionManager.POST(self.controlURL.absoluteString, parameters: parameters, success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                    let responseObject = responseObject as? [String: String]
                    success(newID: responseObject?["NewID"])
                    }, failure: { (task: NSURLSessionDataTask?, error: NSError) -> Void in
                        failure(error: error)
                })
            } else {
                failure(error: createError("SOAP action '\(parameters.soapAction)' unsupported by service \(self.urn) on device \(self.device?.friendlyName)"))
            }
        }
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isContentDirectory1Service() -> Bool {
        return self is ContentDirectory1Service
    }
}

/// overrides ExtendedPrintable protocol implementation
extension ContentDirectory1Service {
    override public var className: String { return "\(self.dynamicType)" }
    override public var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}

class ContentDirectoryBrowseResultParser: AbstractDOMXMLParser {
    private var _contentDirectoryObjects = [ContentDirectory1Object]()
    
    override func parse(document document: ONOXMLDocument) -> EmptyResult {
        let result: EmptyResult = .Success
        document.definePrefix("didllite", forDefaultNamespace: "urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/")
        document.enumerateElementsWithXPath("/didllite:DIDL-Lite/*", usingBlock: { [unowned self] (element: ONOXMLElement!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            switch element.firstChildWithTag("class").stringValue() {
            case .Some(let rawType) where rawType.rangeOfString("object.container") != nil: // some servers use object.container and some use object.container.storageFolder
                if let contentDirectoryObject = ContentDirectory1Container(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            case .Some(let rawType) where rawType == "object.item.videoItem":
                if let contentDirectoryObject = ContentDirectory1VideoItem(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            case .Some(let rawType) where rawType == "object.item.audioItem":
                if let contentDirectoryObject = ContentDirectory1AudioItem(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            default:
                if let contentDirectoryObject = ContentDirectory1Object(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            }
        })
        
        return result
    }
    
    func parse(browseResultData browseResultData: NSData) -> Result<[ContentDirectory1Object]> {
        switch super.parse(data: browseResultData) {
        case .Success:
            return .Success(_contentDirectoryObjects)
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
