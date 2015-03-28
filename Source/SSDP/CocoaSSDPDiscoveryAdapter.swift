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
    private let _serialSSDPDiscoveryQueue = dispatch_queue_create("com.upnatom.cocoa-ssdp-discovery-adapter.ssdp-discovery-queue", DISPATCH_QUEUE_SERIAL)
    private var _ssdpDiscoveries = [String: SSDPDiscovery]()
    
    required init() {
        super.init()
        for ssdpBrowser in _ssdpBrowsers {
            ssdpBrowser.delegate = self
        }
    }
    
    override func start() {
        super.start()
        
        for ssdpBrowser in _ssdpBrowsers {
            ssdpBrowser.startBrowsingForServices()
        }
    }
    
    override func stop() {
        for ssdpBrowser in _ssdpBrowsers {
            ssdpBrowser.stopBrowsingForServices()
        }
        _ssdpDiscoveries.removeAll(keepCapacity: false)
        
        super.stop()
    }
}

extension CocoaSSDPDiscoveryAdapter: SSDPServiceBrowserDelegate {
    @objc func ssdpBrowser(browser: SSDPServiceBrowser!, didNotStartBrowsingForServices error: NSError!) {
        if let delegate = self.delegate {
            delegate.ssdpDiscoveryAdapter(self, didFailWithError: error)
        }
    }
    
    @objc func ssdpBrowser(browser: SSDPServiceBrowser!, didFindService ssdpDiscoveryUnadapted: SSDPService!) {
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            if self._ssdpDiscoveries[ssdpDiscoveryUnadapted.uniqueServiceName] == nil &&
                returnIfContainsElements(ssdpDiscoveryUnadapted.uniqueServiceName) != nil &&
                ssdpDiscoveryUnadapted.location != nil &&
                returnIfContainsElements(ssdpDiscoveryUnadapted.serviceType) != nil {
                    if let usn = UniqueServiceName(rawValue: ssdpDiscoveryUnadapted.uniqueServiceName),
                        descriptionURL = ssdpDiscoveryUnadapted.location {
                            let notificationType = SSDPNotificationType(notificationType: ssdpDiscoveryUnadapted.serviceType)
                            
                            let ssdpDiscovery = SSDPDiscovery(usn: usn, descriptionURL: descriptionURL, notificationType: notificationType)
                            
                            self._ssdpDiscoveries[ssdpDiscoveryUnadapted.uniqueServiceName] = ssdpDiscovery
                            
                            if let delegate = self.delegate {
                                delegate.ssdpDiscoveryAdapter(self, didUpdateSSDPDiscoveries: self._ssdpDiscoveries.values.array)
                            }
                    }
            }
        })
    }
    
    /// Untested as it isn't implemented in CocoaSSDP library
    @objc func ssdpBrowser(browser: SSDPServiceBrowser!, didRemoveService ssdpDiscoveryUnadapted: SSDPService!) {
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            if self._ssdpDiscoveries[ssdpDiscoveryUnadapted.uniqueServiceName] != nil {
                self._ssdpDiscoveries.removeValueForKey(ssdpDiscoveryUnadapted.uniqueServiceName)
                
                if let delegate = self.delegate {
                    delegate.ssdpDiscoveryAdapter(self, didUpdateSSDPDiscoveries: self._ssdpDiscoveries.values.array)
                }
            }
        })
    }
}
