//
//  ViewController.swift
//  ControlPointDemo
//
//  Created by David Robles on 3/9/15.
//  Copyright (c) 2015 David Robles. All rights reserved.
//

import UIKit
import UPnAtom

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserverForName(UPnPRegistry.UPnPDeviceAddedNotification(), object: nil, queue: NSOperationQueue.mainQueue()) { (notification: NSNotification!) -> Void in
            if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
                println("Added device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UPnPRegistry.UPnPServiceAddedNotification(), object: nil, queue: NSOperationQueue.mainQueue()) { (notification: NSNotification!) -> Void in
            if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
                println("Added service: \(upnpService.className) - \(upnpService.descriptionURL)")
            }
        }

        UPnAtom.sharedInstance.startSSDPDiscovery()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

