//
//  SSDPExplorerDiscoveryAdapter.swift
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

class SSDPExplorerDiscoveryAdapter: AbstractSSDPDiscoveryAdapter {
    lazy private var _ssdpExplorer = SSDPExplorer()
    private let _serialSSDPDiscoveryQueue = dispatch_queue_create("com.upnatom.ssdp-explorer-discovery-adapter.ssdp-discovery-queue", DISPATCH_QUEUE_SERIAL)
    private var _ssdpDiscoveries = [UniqueServiceName: SSDPDiscovery]()
    
    required init() {
        super.init()
        
        _ssdpExplorer.delegate = self
    }
    
    override func start() {
        super.start()
        
        let types: Set = [
            SSDPType(typeConstant: .All)!,
            SSDPType(typeConstant: .MediaServerDevice1)!,
            SSDPType(typeConstant: .MediaRendererDevice1)!,
            SSDPType(typeConstant: .ContentDirectory1Service)!,
            SSDPType(typeConstant: .ConnectionManager1Service)!,
            SSDPType(typeConstant: .RenderingControl1Service)!,
            SSDPType(typeConstant: .AVTransport1Service)!
        ]
        if let resultError = _ssdpExplorer.startExploring(forTypes: types).error {
            failed🔰()
            delegate?.ssdpDiscoveryAdapter(self, didFailWithError: resultError)
        }
    }
    
    override func stop() {
        _ssdpExplorer.stopExploring()
        _ssdpDiscoveries.removeAll(keepCapacity: false)
        
        super.stop()
    }
}

extension SSDPExplorerDiscoveryAdapter: SSDPExplorerDelegate {
    func ssdpExplorer(explorer: SSDPExplorer, didMakeDiscovery discovery: SSDPDiscovery) {
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            self._ssdpDiscoveries[discovery.usn] = discovery
            
            self.delegate?.ssdpDiscoveryAdapter(self, didUpdateSSDPDiscoveries: self._ssdpDiscoveries.values.array)
        })
    }
    
    func ssdpExplorer(explorer: SSDPExplorer, didRemoveDiscovery discovery: SSDPDiscovery) {
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            if let discovery = self._ssdpDiscoveries[discovery.usn] {
                self._ssdpDiscoveries.removeValueForKey(discovery.usn)
                
                self.delegate?.ssdpDiscoveryAdapter(self, didUpdateSSDPDiscoveries: self._ssdpDiscoveries.values.array)
            }
        })
    }
    
    func ssdpExplorer(explorer: SSDPExplorer, didFailWithError error: NSError) {
        failed🔰()
        delegate?.ssdpDiscoveryAdapter(self, didFailWithError: error)
    }
}
