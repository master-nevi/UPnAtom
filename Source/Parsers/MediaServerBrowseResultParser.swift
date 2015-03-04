//
//  MediaServerBrowseResultParser.swift
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

import UIKit
import Ono

class MediaServerBrowseResultParser: AbstractDOMXMLParser {
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
        //        println("RESPONSE: \(NSString(data: soapResponseData, encoding: NSUTF8StringEncoding))")
        switch super.parse(data: browseResultData) {
        case .Success:
            return .Success(_contentDirectoryObjects)
        case .Failure(let error):
            return .Failure(error)
        }
    }
}
