//
//  UPnAtom.swift
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

@objc public class UPnAtom {
    // public
    public static let sharedInstance = UPnAtom()
    public let upnpRegistry: UPnPRegistry
    
    // internal
    unowned let ssdpDiscoveryAdapter: SSDPDiscoveryAdapter
    let eventSubscriptionManager: UPnPEventSubscriptionManager
    
    init() {
        if !NSThread.isMainThread() {
            fatalError("UPnAtom singleton must be initialized on main thread")
        }
        
        let adapterClass = UPnAtom.ssdpDiscoveryAdapterClass()
        let adapter = adapterClass()
        ssdpDiscoveryAdapter = adapter
        upnpRegistry = UPnPRegistry(ssdpDiscoveryAdapter: ssdpDiscoveryAdapter)
        eventSubscriptionManager = UPnPEventSubscriptionManager()
    }
    
    deinit {
        ssdpDiscoveryAdapter.stop()
    }
    
    public func ssdpDiscoveryRunning() -> Bool {
        return ssdpDiscoveryAdapter.running
    }
    
    public func startSSDPDiscovery() {
        ssdpDiscoveryAdapter.start()
    }
    
    public func stopSSDPDiscovery() {
        ssdpDiscoveryAdapter.stop()
    }
    
    public func restartSSDPDiscovery() {
        ssdpDiscoveryAdapter.restart()
    }
    
    /// Override to use a different SSDP adapter if another SSDP system is preferred over CocoaSSDP
    class func ssdpDiscoveryAdapterClass() -> AbstractSSDPDiscoveryAdapter.Type {
        return CocoaSSDPDiscoveryAdapter.self
    }
}
