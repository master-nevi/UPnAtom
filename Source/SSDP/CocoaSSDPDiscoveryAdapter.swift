//
//  CocoaSSDPDiscoveryAdapter.swift
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
import CocoaSSDP

class CocoaSSDPDiscoveryAdapter: AbstractSSDPDiscoveryAdapter {
    private let _ssdpBrowsers = [
        SSDPServiceBrowser(serviceType: SSDPServiceType_All),
        SSDPServiceBrowser(serviceType: SSDPServiceType_UPnP_MediaServer1),
        SSDPServiceBrowser(serviceType: SSDPServiceType_UPnP_MediaRenderer1),
        SSDPServiceBrowser(serviceType: SSDPServiceType_UPnP_ContentDirectory1),
        SSDPServiceBrowser(serviceType: SSDPServiceType_UPnP_ConnectionManager1),
        SSDPServiceBrowser(serviceType: SSDPServiceType_UPnP_RenderingControl1),
        SSDPServiceBrowser(serviceType: SSDPServiceType_UPnP_AVTransport1)
    ]
    private let _serialSSDPObjectQueue = dispatch_queue_create("com.upnatom.cocoa-ssdp-discovery-adapter.ssdp-object-queue", DISPATCH_QUEUE_SERIAL)
    private var _ssdpObjects = [String: SSDPObject]()
    
    required init() {
        super.init()
        for ssdpBrowser in _ssdpBrowsers {
            ssdpBrowser.delegate = self
        }
    }
    
    override func start() {
        for ssdpBrowser in _ssdpBrowsers {
            ssdpBrowser.startBrowsingForServices()
        }
    }
    
    override func stop() {
        for ssdpBrowser in _ssdpBrowsers {
            ssdpBrowser.stopBrowsingForServices()
        }
        _ssdpObjects.removeAll(keepCapacity: false)
    }
}

extension CocoaSSDPDiscoveryAdapter: SSDPServiceBrowserDelegate {
    func ssdpBrowser(browser: SSDPServiceBrowser!, didNotStartBrowsingForServices error: NSError!) {
        if let delegate = self.delegate {
            delegate.ssdpDiscoveryAdapter(self, didFailWithError: error)
        }
    }
    
    func ssdpBrowser(browser: SSDPServiceBrowser!, didFindService ssdpObjectUnadapted: SSDPService!) {
        dispatch_async(_serialSSDPObjectQueue, { () -> Void in
            if self._ssdpObjects[ssdpObjectUnadapted.uniqueServiceName] == nil {
                if returnIfContainsElements(ssdpObjectUnadapted.uniqueServiceName) != nil &&
                    ssdpObjectUnadapted.location != nil &&
                    returnIfContainsElements(ssdpObjectUnadapted.serviceType) != nil {
                        let usn = ssdpObjectUnadapted.uniqueServiceName
                        let uuid = returnIfContainsElements(SSDPObject.uuid(usn))
                        let urn = returnIfContainsElements(SSDPObject.urn(usn))
                        let xmlLocation = ssdpObjectUnadapted.location
                        let notificationType = SSDPNotificationType(notificationType: ssdpObjectUnadapted.serviceType)
                        
                        if uuid == nil || xmlLocation == nil {
                            return
                        }
                        
                        let ssdpObject = SSDPObject(uuid: uuid!, urn: urn, usn: usn, xmlLocation: xmlLocation, notificationType: notificationType)
                        
                        self._ssdpObjects[ssdpObjectUnadapted.uniqueServiceName] = ssdpObject
                        
                        if let delegate = self.delegate {
                            delegate.ssdpDiscoveryAdapter(self, didUpdateSSDPObjects: self._ssdpObjects.values.array)
                        }
                }
            }
        })
    }
    
    /// Untested as it isn't implemented in CocoaSSDP library
    func ssdpBrowser(browser: SSDPServiceBrowser!, didRemoveService ssdpObjectUnadapted: SSDPService!) {
        dispatch_async(_serialSSDPObjectQueue, { () -> Void in
            if self._ssdpObjects[ssdpObjectUnadapted.uniqueServiceName] != nil {
                self._ssdpObjects.removeValueForKey(ssdpObjectUnadapted.uniqueServiceName)
                
                if let delegate = self.delegate {
                    delegate.ssdpDiscoveryAdapter(self, didUpdateSSDPObjects: self._ssdpObjects.values.array)
                }
            }
        })
    }
}
