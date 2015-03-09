//
//  UPNPXSSDPDiscoveryAdapter.swift
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
import upnpx

class UPNPXSSDPDiscoveryAdapter: AbstractSSDPDiscoveryAdapter {
    private let _ssdpDB = SSDPDB_ObjC()
    private let _serialSSDPObjectQueue = dispatch_queue_create("com.upnatom.upnp-ssdp-discovery-adapter.ssdp-object-queue", DISPATCH_QUEUE_SERIAL)
    
    required init() {
        super.init()
        _ssdpDB.addObserver(self)
        _ssdpDB.startSSDP()
    }
    
    override func start() {
        _ssdpDB.searchSSDP()
        _ssdpDB.searchForMediaServer()
        _ssdpDB.searchForMediaRenderer()
        _ssdpDB.searchForContentDirectory()
    }
    
    override func stop() {
        _ssdpDB.stopSSDP()
    }
}

extension UPNPXSSDPDiscoveryAdapter: SSDPDB_ObjC_Observer {
    func SSDPDBWillUpdate(sender: SSDPDB_ObjC!) {
        
    }
    
    func SSDPDBUpdated(sender: SSDPDB_ObjC!) {
        let ssdpObjectsUnadapted = sender.SSDPObjCDevices.copy() as [SSDPDBDevice_ObjC]
        dispatch_async(_serialSSDPObjectQueue, { () -> Void in
            var ssdpObjects = [SSDPObject]()
            for ssdpObjectUnadapted in ssdpObjectsUnadapted {
                if returnIfContainsElements(ssdpObjectUnadapted.uuid) != nil &&
                    returnIfContainsElements(ssdpObjectUnadapted.usn) != nil &&
                    returnIfContainsElements(ssdpObjectUnadapted.location) != nil &&
                    returnIfContainsElements(ssdpObjectUnadapted.type) != nil {
                        var notificationType: SSDPNotificationType
                        if ssdpObjectUnadapted.isdevice {
                            notificationType = .Device
                        }
                        else if ssdpObjectUnadapted.isservice {
                            notificationType = .Service
                        }
                        else if ssdpObjectUnadapted.isroot {
                            notificationType = .RootDevice
                        }
                        else {
                            notificationType = .Unknown
                        }
                        
                        ssdpObjects.append(SSDPObject(uuid: ssdpObjectUnadapted.uuid, urn: ssdpObjectUnadapted.urn, usn: ssdpObjectUnadapted.usn, xmlLocation: NSURL(string: ssdpObjectUnadapted.location)!, notificationType: notificationType))
                }
            }
            
            if let delegate = self.delegate {
                delegate.ssdpDiscoveryAdapter(self, didUpdateSSDPObjects: ssdpObjects)
            }
        })
    }
}
