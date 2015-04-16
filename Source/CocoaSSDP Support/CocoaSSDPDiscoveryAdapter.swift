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
    /// Must be set before calling start()
    lazy private var _ssdpBrowsers: Set<SSDPServiceBrowser> = {
        var ssdpBrowsers = Set<SSDPServiceBrowser>()
        for type in self.rawSSDPTypes {
            let ssdpBrowser = SSDPServiceBrowser(serviceType: type)
            ssdpBrowser.delegate = self
            ssdpBrowsers.insert(ssdpBrowser)
        }
        
        return ssdpBrowsers
    }()
    /// Never reading without writing so a serial queue is adequate
    private let _serialSSDPDiscoveryQueue = dispatch_queue_create("com.upnatom.cocoa-ssdp-discovery-adapter.ssdp-discovery-queue", DISPATCH_QUEUE_SERIAL)
    /// Must be accessed and updated within dispatch_sync() or dispatch_async() to the serial queue
    private var _ssdpDiscoveries = [String: SSDPDiscovery]()
    
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
        
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            self._ssdpDiscoveries.removeAll(keepCapacity: false)
            
            self.notifyDelegate(ofDiscoveries: self._ssdpDiscoveries.values.array)
        })
        
        super.stop()
    }
    
    private func notifyDelegate(ofFailure error: NSError) {
        dispatch_async(delegateQueue, { () -> Void in
            delegate?.ssdpDiscoveryAdapter(self, didFailWithError: error)
        })
    }
    
    private func notifyDelegate(ofDiscoveries discoveries: [SSDPDiscovery]) {
        dispatch_async(delegateQueue, { () -> Void in
            self.delegate?.ssdpDiscoveryAdapter(self, didUpdateSSDPDiscoveries: discoveries)
        })
    }
}

extension CocoaSSDPDiscoveryAdapter: SSDPServiceBrowserDelegate {
    @objc func ssdpBrowser(browser: SSDPServiceBrowser!, didNotStartBrowsingForServices error: NSError!) {
        failed🔰()
        delegate?.ssdpDiscoveryAdapter(self, didFailWithError: error)
    }
    
    @objc func ssdpBrowser(browser: SSDPServiceBrowser!, didFindService ssdpDiscoveryUnadapted: SSDPService!) {
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            if self._ssdpDiscoveries[ssdpDiscoveryUnadapted.uniqueServiceName] == nil &&
                returnIfContainsElements(ssdpDiscoveryUnadapted.uniqueServiceName) != nil &&
                ssdpDiscoveryUnadapted.location != nil &&
                returnIfContainsElements(ssdpDiscoveryUnadapted.serviceType) != nil {
                    if let usn = UniqueServiceName(rawValue: ssdpDiscoveryUnadapted.uniqueServiceName),
                        descriptionURL = ssdpDiscoveryUnadapted.location,
                        ssdpType = SSDPType(rawValue: ssdpDiscoveryUnadapted.serviceType) {
                            let ssdpDiscovery = SSDPDiscovery(usn: usn, descriptionURL: descriptionURL, type: ssdpType)
                            
                            self._ssdpDiscoveries[ssdpDiscoveryUnadapted.uniqueServiceName] = ssdpDiscovery

                            self.notifyDelegate(ofDiscoveries: self._ssdpDiscoveries.values.array)
                    }
            }
        })
    }
    
    @objc func ssdpBrowser(browser: SSDPServiceBrowser!, didRemoveService ssdpDiscoveryUnadapted: SSDPService!) {
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            if self._ssdpDiscoveries[ssdpDiscoveryUnadapted.uniqueServiceName] != nil {
                self._ssdpDiscoveries.removeValueForKey(ssdpDiscoveryUnadapted.uniqueServiceName)
                
                self.notifyDelegate(ofDiscoveries: self._ssdpDiscoveries.values.array)
            }
        })
    }
}
