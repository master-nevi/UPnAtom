//
//  ViewController.swift
//  ControlPointDemo
//
//  Created by David Robles on 8/21/16.
//  Copyright © 2016 David Robles. All rights reserved.
//

import Cocoa
import UPnAtom

class ViewController: NSViewController {
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.deviceWasAdded(_:)), name: UPnPRegistry.UPnPDeviceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.deviceWasRemoved(_:)), name: UPnPRegistry.UPnPDeviceRemovedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.serviceWasAdded(_:)), name: UPnPRegistry.UPnPServiceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.serviceWasRemoved(_:)), name: UPnPRegistry.UPnPServiceRemovedNotification(), object: nil)
        
        UPnAtom.sharedInstance.ssdpTypes = [
            SSDPTypeConstant.All.rawValue,
            SSDPTypeConstant.MediaServerDevice1.rawValue,
            SSDPTypeConstant.MediaRendererDevice1.rawValue,
            SSDPTypeConstant.ContentDirectory1Service.rawValue,
            SSDPTypeConstant.ConnectionManager1Service.rawValue,
            SSDPTypeConstant.RenderingControl1Service.rawValue,
            SSDPTypeConstant.AVTransport1Service.rawValue
        ]
        
        if !UPnAtom.sharedInstance.ssdpDiscoveryRunning() {
            UPnAtom.sharedInstance.startSSDPDiscovery()
        }
    }
    
    override func viewDidDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPDeviceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPDeviceRemovedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPServiceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPServiceRemovedNotification(), object: nil)
        
        super.viewDidDisappear()
    }
    
    @objc private func deviceWasAdded(notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            print("Added device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
        }
    }
    
    @objc private func deviceWasRemoved(notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            print("Removed device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
        }
    }
    
    @objc private func serviceWasAdded(notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            print("Added service: \(upnpService.className) - \(upnpService.descriptionURL)")
            
            if upnpService is AVTransport1Service {
                upnpService.addEventObserver(NSOperationQueue.currentQueue(), callBackBlock: { (event: UPnPEvent) -> Void in
                    if let avTransportEvent = event as? AVTransport1Event {
                        print("\(event.service?.className) Event: \(avTransportEvent.instanceState)")
                    }
                })
            }
        }
    }
    
    @objc private func serviceWasRemoved(notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            print("Removed service: \(upnpService.className) - \(upnpService.descriptionURL)")
        }
    }
}
