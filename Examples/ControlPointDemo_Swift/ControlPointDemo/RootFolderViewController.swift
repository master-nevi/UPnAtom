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
    private var _discoveredDeviceUSNs = [UniqueServiceName]()
    private var _discoveredUPnPObjectCache = [UniqueServiceName: AbstractUPnP]()
    private var _archivedDeviceUSNs = [UniqueServiceName]()
    private var _archivedUPnPObjectCache = [UniqueServiceName: AbstractUPnP]()
    private static let upnpObjectArchiveKey = "upnpObjectArchiveKey"
    private weak var _toolbarLabel: UILabel?
    @IBOutlet private weak var _tableView: UITableView!
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
        performSSDPDiscovery()
    }
    
    @IBAction private func archiveButtonTapped(sender: AnyObject) {
        archiveUPnPObjects()
    }

    @objc private func deviceWasAdded(notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            println("Added device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
            
            _discoveredUPnPObjectCache[upnpDevice.usn] = upnpDevice
            insertDevice(deviceUSN: upnpDevice.usn, deviceUSNs: &_discoveredDeviceUSNs, inSection: 1)
        }
    }
    
    @objc private func deviceWasRemoved(notification: NSNotification) {
        if let upnpDevice = notification.userInfo?[UPnPRegistry.UPnPDeviceKey()] as? AbstractUPnPDevice {
            println("Removed device: \(upnpDevice.className) - \(upnpDevice.friendlyName)")
            
            _discoveredUPnPObjectCache.removeValueForKey(upnpDevice.usn)
            deleteDevice(deviceUSN: upnpDevice.usn, deviceUSNs: &_discoveredDeviceUSNs, inSection: 1)
        }
    }
    
    @objc private func serviceWasAdded(notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            let friendlyName = (upnpService.device != nil) ? upnpService.device!.friendlyName : "Service's device object not created yet"
            println("Added service: \(upnpService.className) - \(friendlyName)")
            
            _discoveredUPnPObjectCache[upnpService.usn] = upnpService
        }
    }
    
    @objc private func serviceWasRemoved(notification: NSNotification) {
        if let upnpService = notification.userInfo?[UPnPRegistry.UPnPServiceKey()] as? AbstractUPnPService {
            let friendlyName = (upnpService.device != nil) ? upnpService.device!.friendlyName : "Service's device object not created yet"
            println("Removed service: \(upnpService.className) - \(friendlyName)")
            
            _discoveredUPnPObjectCache[upnpService.usn] = upnpService
        }
    }
    
    private func deviceCountForTableSection(section: Int) -> Int {
        return section == 0 ? _archivedDeviceUSNs.count : _discoveredDeviceUSNs.count
    }
    
    private func deviceForIndexPath(indexPath: NSIndexPath) -> AbstractUPnPDevice {
        let deviceUSN = indexPath.section == 0 ? _archivedDeviceUSNs[indexPath.row] : _discoveredDeviceUSNs[indexPath.row]
        let deviceCache = indexPath.section == 0 ? _archivedUPnPObjectCache : _discoveredUPnPObjectCache
        return deviceCache[deviceUSN] as! AbstractUPnPDevice
    }
    
    private func insertDevice(#deviceUSN: UniqueServiceName, inout deviceUSNs: [UniqueServiceName], inSection section: Int) {
        let index = deviceUSNs.count
        deviceUSNs.insert(deviceUSN, atIndex: index)
        let indexPath = NSIndexPath(forRow: index, inSection: section)
        self._tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    private func deleteDevice(#deviceUSN: UniqueServiceName, inout deviceUSNs: [UniqueServiceName], inSection section: Int) {
        if let index = find(deviceUSNs, deviceUSN) {
            deviceUSNs.removeAtIndex(index)
            let indexPath = NSIndexPath(forRow: index, inSection: section)
            self._tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    private func performSSDPDiscovery() {
        if UPnAtom.sharedInstance.ssdpDiscoveryRunning() {
            UPnAtom.sharedInstance.restartSSDPDiscovery()
        }
        else {
            UPnAtom.sharedInstance.startSSDPDiscovery()
        }
    }
    
    private func archiveUPnPObjects() {
        _archivingUnarchivingQueue.addOperationWithBlock { () -> Void in
            // archive discovered objects
            var upnpArchivables = [UPnPArchivableAnnex]()
            for (usn, upnpObject) in self._discoveredUPnPObjectCache {
                var friendlyName = "Unknown"
                if let upnpDevice = upnpObject as? AbstractUPnPDevice {
                    friendlyName = upnpDevice.friendlyName
                }
                else if let upnpService = upnpObject as? AbstractUPnPService,
                    name = upnpService.device?.friendlyName {
                        friendlyName = name
                }
                
                let upnpArchivable = upnpObject.archivable(customMetadata: ["upnpType": upnpObject.className, "friendlyName": friendlyName])
                upnpArchivables.append(upnpArchivable)
            }
            
            let upnpArchivablesData = NSKeyedArchiver.archivedDataWithRootObject(upnpArchivables)
            NSUserDefaults.standardUserDefaults().setObject(upnpArchivablesData, forKey: RootFolderViewController.upnpObjectArchiveKey)
            
            // show archive complete alert
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                let alertController = UIAlertController(title: "Archive Complete!", message: "Load archive and reload table view? If cancelled you'll see the archived devices on the next launch.", preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction!) -> Void in
                    self.loadArchivedUPnPObjects()
                }))
                self.presentViewController(alertController, animated: true, completion: nil)
            })
        }
    }
    
    private func loadArchivedUPnPObjects() {
        // clear previously loaded archive devices
        if _archivedDeviceUSNs.count > 0 {
            var currentArchivedDeviceIndexes = [NSIndexPath]()
            for var i: Int = 0; i < _archivedDeviceUSNs.count; i++ {
                currentArchivedDeviceIndexes.append(NSIndexPath(forRow: i, inSection: 0))
            }
            
            _archivedDeviceUSNs.removeAll(keepCapacity: false)
            _tableView.deleteRowsAtIndexPaths(currentArchivedDeviceIndexes, withRowAnimation: .Automatic)
        }
        
        // clear archive model
        _archivedUPnPObjectCache.removeAll(keepCapacity: false)
        
        _archivingUnarchivingQueue.addOperationWithBlock { () -> Void in
            // load archived objects
            if let upnpArchivablesData = NSUserDefaults.standardUserDefaults().objectForKey(RootFolderViewController.upnpObjectArchiveKey) as? NSData {
                let upnpArchivables = NSKeyedUnarchiver.unarchiveObjectWithData(upnpArchivablesData) as! [UPnPArchivableAnnex]
                
                for upnpArchivable in upnpArchivables {
                    let upnpType = upnpArchivable.customMetadata["upnpType"] as? String
                    let friendlyName = upnpArchivable.customMetadata["friendlyName"] as? String
                    println("Unarchived upnp object from cache \(upnpType) - \(friendlyName)")
                    
                    UPnAtom.sharedInstance.upnpRegistry.createUPnPObject(upnpArchivable: upnpArchivable, callbackQueue: NSOperationQueue.mainQueue(), success: { (upnpObject: AbstractUPnP) -> Void in
                        println("Re-created upnp object \(upnpObject.className) - \(friendlyName)")
                        
                        self._archivedUPnPObjectCache[upnpObject.usn] = upnpObject
                        
                        if let upnpDevice = upnpObject as? AbstractUPnPDevice {
                            upnpDevice.serviceSource = self
                            
                            self.insertDevice(deviceUSN: upnpDevice.usn, deviceUSNs: &self._archivedDeviceUSNs, inSection: 0)
                        }
                        else if let upnpService = upnpObject as? AbstractUPnPService {
                            upnpService.deviceSource = self
                        }
                        }, failure: { (error: NSError) -> Void in
                            println("Failed to create UPnP Object from archive")
                    })
                }
            }
            else {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.performSSDPDiscovery()
                })
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
        return deviceCountForTableSection(section)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DefaultCell") as! UITableViewCell
        let device = deviceForIndexPath(indexPath)
        cell.textLabel?.text = device.friendlyName
        cell.accessoryType = device is MediaServer1Device ? .DisclosureIndicator : .None
        
        return cell
    }
}

extension RootFolderViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let device = deviceForIndexPath(indexPath)

        if let mediaServer = device as? MediaServer1Device {
            if mediaServer.contentDirectoryService == nil {
                println("\(mediaServer.friendlyName) - has no content directory service")
                return
            }
            
            let targetViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("FolderViewControllerScene") as! FolderViewController
            targetViewController.configure(mediaServer: mediaServer, title: "Root", contentDirectoryID: "0")
            self.navigationController?.pushViewController(targetViewController, animated: true)
            
            Player.sharedInstance.mediaServer = mediaServer
        }
        else if let mediaRenderer = device as? MediaRenderer1Device {
            if mediaRenderer.avTransportService == nil {
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
        return _archivedUPnPObjectCache[usn] as? AbstractUPnPService
    }
}

extension RootFolderViewController: UPnPDeviceSource {
    func deviceFor(#usn: UniqueServiceName) -> AbstractUPnPDevice? {
        return _archivedUPnPObjectCache[usn] as? AbstractUPnPDevice
    }
}
