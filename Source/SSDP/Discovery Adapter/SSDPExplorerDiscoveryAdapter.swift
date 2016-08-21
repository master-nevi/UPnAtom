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
    /// Never reading without writing so a serial queue is adequate
    private let _serialSSDPDiscoveryQueue = dispatch_queue_create("com.upnatom.ssdp-explorer-discovery-adapter.ssdp-discovery-queue", DISPATCH_QUEUE_SERIAL)
    /// Must be accessed and updated within dispatch_sync() or dispatch_async() to the serial queue
    private var _ssdpDiscoveries = [UniqueServiceName: SSDPDiscovery]()
    
    required init() {
        super.init()
        
        _ssdpExplorer.delegate = self
    }
    
    override func start() {
        super.start()
        
        var types = [SSDPType]() // TODO: Should ideally be a Set<SSDPType>, see Github issue #13
        for rawSSDPType in rawSSDPTypes {
            if let ssdpType = SSDPType(rawValue: rawSSDPType) {
                types.append(ssdpType)
            }
        }
        if let resultError = _ssdpExplorer.startExploring(forTypes: types).error {
            failed🔰()
            notifyDelegate(ofFailure: resultError)
        }
    }
    
    override func stop() {
        _ssdpExplorer.stopExploring()
        
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            self._ssdpDiscoveries.removeAll(keepCapacity: false)
            
            self.notifyDelegate(ofDiscoveries: Array(self._ssdpDiscoveries.values))
        })
        
        super.stop()
    }
    
    private func notifyDelegate(ofFailure error: NSError) {
        dispatch_async(delegateQueue, { () -> Void in
            self.delegate?.ssdpDiscoveryAdapter(self, didFailWithError: error)
        })
    }
    
    private func notifyDelegate(ofDiscoveries discoveries: [SSDPDiscovery]) {
        dispatch_async(delegateQueue, { () -> Void in
            self.delegate?.ssdpDiscoveryAdapter(self, didUpdateSSDPDiscoveries: discoveries)
        })
    }
}

extension SSDPExplorerDiscoveryAdapter: SSDPExplorerDelegate {
    func ssdpExplorer(explorer: SSDPExplorer, didMakeDiscovery discovery: SSDPDiscovery) {
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            self._ssdpDiscoveries[discovery.usn] = discovery
            
            self.notifyDelegate(ofDiscoveries: Array(self._ssdpDiscoveries.values))
        })
    }
    
    func ssdpExplorer(explorer: SSDPExplorer, didRemoveDiscovery discovery: SSDPDiscovery) {
        dispatch_async(_serialSSDPDiscoveryQueue, { () -> Void in
            if let discovery = self._ssdpDiscoveries[discovery.usn] {
                self._ssdpDiscoveries.removeValueForKey(discovery.usn)
                
                self.notifyDelegate(ofDiscoveries: Array(self._ssdpDiscoveries.values))
            }
        })
    }
    
    func ssdpExplorer(explorer: SSDPExplorer, didFailWithError error: NSError) {
        failed🔰()
        notifyDelegate(ofFailure: error)
    }
}
