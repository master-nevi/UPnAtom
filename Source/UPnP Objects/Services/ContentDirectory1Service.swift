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
import upnpx
import Ono

public class ContentDirectory1Service: AbstractUPnPService {    
    public func getSortCapabilities(success: (sortCapabilities: String?) -> Void, failure:(error: NSError?) -> Void) {
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "GetSortCapabilities", serviceURN: urn, arguments: nil)
        
        sessionManager🔰.POST(controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            let responseObject = responseObject as? [String: String]
            success(sortCapabilities: responseObject?["SortCaps"])
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
    
    public func browse(#objectID: String, browseFlag: String, filter: String, startingIndex: String, requestedCount: String, sortCriteria: String, success: (result: [ContentDirectory1Object]?, numberReturned: String?, totalMatches: String?, updateID: String?) -> Void, failure: (error: NSError?) -> Void) {
        let arguments = [
            "ObjectID" : objectID,
            "BrowseFlag" : browseFlag,
            "Filter": filter,
            "StartingIndex" : startingIndex,
            "RequestedCount" : requestedCount,
            "SortCriteria" : sortCriteria]
        
        let parameters = SOAPRequestSerializer.Parameters(soapAction: "Browse", serviceURN: urn, arguments: arguments)
        
        sessionManager🔰.POST(controlURL.absoluteString!, parameters: parameters, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                let responseObject = responseObject as? [String: String]
                
                var result: [ContentDirectory1Object]?
                if let resultString = responseObject?["Result"] {
                    result = ContentDirectoryBrowseResultParser().parse(browseResultData: resultString.dataUsingEncoding(NSUTF8StringEncoding)!).value
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    success(result: result, numberReturned: responseObject?["NumberReturned"], totalMatches: responseObject?["TotalMatches"], updateID: responseObject?["UpdateID"])
                })
            })
            }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
                failure(error: error)
        })
    }
}

/// for objective-c type checking
extension AbstractUPnP {
    public func isContentDirectory1Service() -> Bool {
        return self is ContentDirectory1Service
    }
}

extension ContentDirectory1Service: ExtendedPrintable {
    override public var className: String { return "ContentDirectory1Service" }
    override public var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}

class ContentDirectoryBrowseResultParser: AbstractDOMXMLParser {
    private var _contentDirectoryObjects = [ContentDirectory1Object]()
    
    override func parse(#document: ONOXMLDocument) -> EmptyResult {
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
            default:
                if let contentDirectoryObject = ContentDirectory1Object(xmlElement: element) {
                    self._contentDirectoryObjects.append(contentDirectoryObject)
                }
            }
        })
        
        return result
    }
    
    func parse(#browseResultData: NSData) -> Result<[ContentDirectory1Object]> {
        switch super.parse(data: browseResultData) {
        case .Success:
            return .Success(_contentDirectoryObjects)
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
