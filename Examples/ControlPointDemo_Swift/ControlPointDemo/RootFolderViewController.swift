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
    private var _discoveredDevices = [AbstractUPnPDevice]()
    private var _archivedDevices = [AbstractUPnPDevice]()
    private var _archivedServices = [UniqueServiceName: AbstractUPnPService]()
    private weak var _toolbarLabel: UILabel?
    @IBOutlet private weak var _tableView: UITableView!
    private let _upnpDeviceArchiveKey = "upnpDeviceArchiveKey"
    private let _upnpServiceArchiveKey = "upnpServiceArchiveKey"
    private let _archivingUnarchivingQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = "Archiving and unarchiving queue"
        return queue
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize
        UPnAtom.sharedInstance
        
        loadArchivedUPnPObjects()
        
        self.title = "Control Point Demo"
        
        let playerButton = Player.sharedInstance.playerButton
        let viewWidth = self.navigationController!.view.frame.size.width
        let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 11.0, width: viewWidth - (viewWidth * 0.2), height: 21.0))
        _toolbarLabel = titleLabel
        titleLabel.font = UIFont(name: "Helvetica", size: 18)
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.textAlignment = .Left
        titleLabel.text = ""
        let barButton = UIBarButtonItem(customView: titleLabel)
        self.toolbarItems = [playerButton, barButton]
        
        self.navigationController?.toolbarHidden = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceWasAdded:", name: UPnPRegistry.UPnPDeviceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceWasRemoved:", name: UPnPRegistry.UPnPDeviceRemovedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "serviceWasAdded:", name: UPnPRegistry.UPnPServiceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "serviceWasRemoved:", name: UPnPRegistry.UPnPServiceRemovedNotification(), object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPDeviceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPDeviceRemovedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPServiceAddedNotification(), object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UPnPRegistry.UPnPServiceRemovedNotification(), object: nil)
        
        super.viewDidDisappear(animated)
    }
    
    @IBAction private func discoverButtonTapped(sender: AnyObject) {
        if UPnAtom.sharedInstance.ssdpDiscoveryRunning() {
            UPnAtom.sharedInstance.restartSSDPDiscovery()
        }
        else {
            UPnAtom.sharedInstance.startSSDPDiscovery()
        }
    }
    
    @IBAction private func archiveButtonTapped(sender: AnyObject) {
        archiveUPnPObjects()
    }

    @objc private func deviceWasAdded(notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            println("Added device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
            
            let index = _discoveredDevices.count
            _discoveredDevices.insert(upnpDevice, atIndex: index)
            
            let indexPath = NSIndexPath(forRow: index, inSection: 1)
            _tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    @objc private func deviceWasRemoved(notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            println("Removed device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
            
            if let index = find(_discoveredDevices, upnpDevice) {
                _discoveredDevices.removeAtIndex(index)
                
                let indexPath = NSIndexPath(forRow: index, inSection: 1)
                _tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }
    
    @objc private func serviceWasAdded(notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            println("Added service: \(upnpService.className)")
        }
    }
    
    @objc private func serviceWasRemoved(notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            println("Removed service: \(upnpService.className)")
        }
    }
    
    private func devicesForTableSection(section: Int) -> [AbstractUPnPDevice] {
        return section == 0 ? _archivedDevices : _discoveredDevices
    }
    
    private func archiveUPnPObjects() {
        // archive devices
        UPnAtom.sharedInstance.upnpRegistry.upnpDevices(completionQueue: _archivingUnarchivingQueue, completion: { (upnpDevices) -> Void in
            var deviceArchivables = [UPnPArchivableAnnex]()
            for device in upnpDevices {
                let deviceArchivable = device.archivable(customMetadata: ["upnpType": device.className, "friendlyName": device.friendlyName])
                deviceArchivables.append(deviceArchivable)
            }
            
            let deviceArchivablesData = NSKeyedArchiver.archivedDataWithRootObject(deviceArchivables)
            NSUserDefaults.standardUserDefaults().setObject(deviceArchivablesData, forKey: self._upnpDeviceArchiveKey)
            
            // archive services
            UPnAtom.sharedInstance.upnpRegistry.upnpServices(completionQueue: self._archivingUnarchivingQueue, completion: { (upnpServices) -> Void in
                var serviceArchivables = [UPnPArchivableAnnex]()
                for service in upnpServices {
                    let serviceArchivable = service.archivable(customMetadata: ["upnpType": service.className])
                    serviceArchivables.append(serviceArchivable)
                }
                
                let serviceArchivablesData = NSKeyedArchiver.archivedDataWithRootObject(serviceArchivables)
                NSUserDefaults.standardUserDefaults().setObject(serviceArchivablesData, forKey: self._upnpServiceArchiveKey)
                
                // show archive complete alert
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    let alertController = UIAlertController(title: "Archive Complete!", message: "Load archive and reload table view? If cancelled you'll see the archived devices on the next launch.", preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction!) -> Void in
                        self.loadArchivedUPnPObjects()
                    }))
                    self.presentViewController(alertController, animated: true, completion: nil)
                })
            })
        })
    }
    
    private func loadArchivedUPnPObjects() {
        // clear previously loaded devices
        if _archivedDevices.count > 0 {
            var currentArchivedDeviceIndexes = [NSIndexPath]()
            for var i: Int = 0; i < _archivedDevices.count; i++ {
                currentArchivedDeviceIndexes.append(NSIndexPath(forRow: i, inSection: 0))
            }
            
            _archivedDevices.removeAll(keepCapacity: false)
            _tableView.deleteRowsAtIndexPaths(currentArchivedDeviceIndexes, withRowAnimation: .Automatic)
        }
        
        // clear previously loaded services
        if _archivedServices.count > 0 {
            _archivedServices.removeAll(keepCapacity: false)
        }
        
        _archivingUnarchivingQueue.addOperationWithBlock { () -> Void in
            // load archived devices
            if let deviceArchivablesData = NSUserDefaults.standardUserDefaults().objectForKey(self._upnpDeviceArchiveKey) as? NSData {
                let deviceArchivables = NSKeyedUnarchiver.unarchiveObjectWithData(deviceArchivablesData) as [UPnPArchivableAnnex]
                
                for deviceArchivable in deviceArchivables {
                    let upnpType = deviceArchivable.customMetadata["upnpType"] as? String
                    let friendlyName = deviceArchivable.customMetadata["friendlyName"] as? String
                    println("Unarchived device from cache \(upnpType) - \(friendlyName)")
                    
                    UPnAtom.sharedInstance.upnpRegistry.createUPnPObject(upnpArchivable: deviceArchivable, callbackQueue: NSOperationQueue.mainQueue(), success: { (upnpObject: AbstractUPnP) -> Void in
                        println("Re-created device \(upnpObject.className) - \(friendlyName)")
                        
                        if let upnpDevice = upnpObject as? AbstractUPnPDevice {
                            upnpDevice.serviceSource = self
                            
                            let index = self._archivedDevices.count
                            self._archivedDevices.insert(upnpDevice, atIndex: index)
                            let indexPath = NSIndexPath(forRow: index, inSection: 0)
                            self._tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                        }
                        }, failure: { (error: NSError) -> Void in
                            println("Failed to create UPnP Object from archive")
                    })
                }
            }
            
            // load archived services
            if let serviceArchivablesData = NSUserDefaults.standardUserDefaults().objectForKey(self._upnpServiceArchiveKey) as? NSData {
                let serviceArchivables = NSKeyedUnarchiver.unarchiveObjectWithData(serviceArchivablesData) as [UPnPArchivableAnnex]
                
                for serviceArchivable in serviceArchivables {
                    let upnpType = serviceArchivable.customMetadata["upnpType"] as? String
                    println("Unarchived service from cache \(upnpType)")
                    
                    UPnAtom.sharedInstance.upnpRegistry.createUPnPObject(upnpArchivable: serviceArchivable, callbackQueue: NSOperationQueue.mainQueue(), success: { (upnpObject: AbstractUPnP) -> Void in
                        println("Re-created service \(upnpObject.className)")
                        
                        if let upnpDevice = upnpObject as? AbstractUPnPService {
                            self._archivedServices[upnpDevice.usn] = upnpDevice
                        }
                        }, failure: { (error: NSError) -> Void in
                            println("Failed to create UPnP Object from archive")
                    })
                }
            }
        }
    }
}

extension RootFolderViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Archived Devices" : "Discovered Devices"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let devices = devicesForTableSection(section)
        return devices.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DefaultCell") as UITableViewCell
        let devices = devicesForTableSection(indexPath.section)
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.friendlyName
        cell.accessoryType = device is MediaServer1Device ? .DisclosureIndicator : .None
        
        return cell
    }
}

extension RootFolderViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let devices = devicesForTableSection(indexPath.section)
        let device = devices[indexPath.row]

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
            
            _toolbarLabel?.text = mediaRenderer.friendlyName
            Player.sharedInstance.mediaRenderer = mediaRenderer
        }
    }
}

extension RootFolderViewController: UPnPServiceSource {
    func serviceFor(#usn: UniqueServiceName) -> AbstractUPnPService? {
        return _archivedServices[usn]
    }
}
