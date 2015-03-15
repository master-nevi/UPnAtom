//
//  RootFolderViewController.swift
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
import UPnAtom

class RootFolderViewController: UIViewController {
    private var _devices = [AbstractUPnPDevice]()
    private var toolbarLabel: UILabel? {
        return (self.toolbarItems?.first as? UIBarButtonItem)?.customView as? UILabel
    }
    @IBOutlet private weak var _tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Control Point Demo"
        
        let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 11.0, width: self.navigationController!.view.frame.size.width, height: 21.0))
        titleLabel.font = UIFont(name: "Helvetica", size: 18)
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.textAlignment = .Left
        titleLabel.text = ""
        let barButton = UIBarButtonItem(customView: titleLabel)
        self.toolbarItems = [barButton]
        
        self.navigationController?.toolbarHidden = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceWasAdded:", name: UPnPRegistry.UPnPDeviceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceWasRemoved:", name: UPnPRegistry.UPnPDeviceRemovedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "serviceWasAdded:", name: UPnPRegistry.UPnPServiceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "serviceWasRemoved:", name: UPnPRegistry.UPnPServiceRemovedNotification(), object: nil)
        
        if !UPnAtom.sharedInstance.ssdpDiscoveryRunning() {
            UPnAtom.sharedInstance.startSSDPDiscovery()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPDeviceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPDeviceRemovedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPServiceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPServiceRemovedNotification(), object: nil)
        
        super.viewDidDisappear(animated)
    }
    
    @IBAction func ssdpSearchButtonTapped(sender: AnyObject) {
        UPnAtom.sharedInstance.restartSSDPDiscovery()
    }

    @objc private func deviceWasAdded(notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            println("Added device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
            
            let index = _devices.count
            _devices.insert(upnpDevice, atIndex: index)
            
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            _tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    @objc private func deviceWasRemoved(notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            println("Removed device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
            
            if let index = find(_devices, upnpDevice) {
                _devices.removeAtIndex(index)
                
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                _tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }
    
    @objc private func serviceWasAdded(notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            println("Added service: \(upnpService.className) - \(upnpService.descriptionURL)")
        }
    }
    
    @objc private func serviceWasRemoved(notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            println("Removed service: \(upnpService.className) - \(upnpService.descriptionURL)")
        }
    }
}

extension RootFolderViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _devices.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DefaultCell") as UITableViewCell
        let device = _devices[indexPath.row]
        cell.textLabel?.text = device.friendlyName
        cell.accessoryType = device is MediaServer1Device ? .DisclosureIndicator : .None
        
        return cell
    }
}

extension RootFolderViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let device = _devices[indexPath.row]

        if let mediaServer = device as? MediaServer1Device {
            if mediaServer.contentDirectoryService() == nil {
                println("\(mediaServer.friendlyName) - has no content directory service")
                return
            }
            
            let targetViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("FolderViewControllerScene") as FolderViewController
            targetViewController.configure(mediaServer: mediaServer, title: "Root", contentDirectoryID: "0")
            self.navigationController?.pushViewController(targetViewController, animated: true)
            
            Player.sharedInstance.mediaServer = mediaServer
        }
        else if let mediaRenderer = device as? MediaRenderer1Device {
            if mediaRenderer.avTransportService() == nil {
                println("\(mediaRenderer.friendlyName) - has no AV transport service")
                return
            }
            
            toolbarLabel?.text = mediaRenderer.friendlyName
            Player.sharedInstance.mediaRenderer = mediaRenderer
        }
    }
}

