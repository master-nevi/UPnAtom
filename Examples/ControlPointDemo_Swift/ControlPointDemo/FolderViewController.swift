//
//  FolderViewController.swift
//  ControlPointDemo
//
//  Created by David Robles on 3/14/15.
//  Copyright (c) 2015 David Robles. All rights reserved.
//

import UIKit
import UPnAtom

class FolderViewController: UIViewController {
    @IBOutlet private weak var _tableView: UITableView!
    private var _playlist = [ContentDirectory1Object]()
    private var _mediaServer: MediaServer1Device!
    private var _contentDirectoryID: String!
    
    func configure(mediaServer mediaServer: MediaServer1Device, title: String, contentDirectoryID: String) {
        _mediaServer = mediaServer
        _contentDirectoryID = contentDirectoryID
        self.title = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        _mediaServer?.contentDirectoryService?.getSortCapabilities({ (sortCapabilities: String?) -> Void in
            var sortCapabilities = sortCapabilities != nil ? sortCapabilities! : ""
            if sortCapabilities.rangeOfString("dc:title") != nil {
                sortCapabilities = "+dc:title"
            }
            
            self._mediaServer?.contentDirectoryService?.browse(objectID: self._contentDirectoryID, browseFlag: "BrowseDirectChildren", filter: "*", startingIndex: "0", requestedCount: "0", sortCriteria: sortCapabilities, success: { (result: [ContentDirectory1Object], numberReturned: Int, totalMatches: Int, updateID: String?) -> Void in
                self._playlist = result
                self._tableView.reloadData()
                }, failure: { (error: NSError) -> Void in
                    print("Failed to browse content directory: \(error)")
            })
            }, failure: { (error: NSError) -> Void in
            print("Failed to get sort capabilities: \(error)")
        })
        
        let viewWidth = self.navigationController!.view.frame.size.width
        let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 11.0, width: viewWidth - (viewWidth * 0.2), height: 21.0))
        titleLabel.font = UIFont(name: "Helvetica", size: 18)
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.textAlignment = .Left
        titleLabel.text = Player.sharedInstance.mediaRenderer == nil ? "No Renderer Selected" : Player.sharedInstance.mediaRenderer?.friendlyName
        let barButton = UIBarButtonItem(customView: titleLabel)
        self.toolbarItems = [Player.sharedInstance.playPauseButton, Player.sharedInstance.stopButton, barButton]
        
        self.navigationController?.toolbarHidden = false
    }
}

extension FolderViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _playlist.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("DefaultCell") as UITableViewCell!
        let item = _playlist[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item is ContentDirectory1Container ? .DisclosureIndicator : .None
        
        return cell
    }
}

extension FolderViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = _playlist[indexPath.row]
        if let containerItem = item as? ContentDirectory1Container {
            let targetViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("FolderViewControllerScene") as! FolderViewController
            targetViewController.configure(mediaServer: _mediaServer, title: containerItem.title, contentDirectoryID: containerItem.objectID)
            self.navigationController?.pushViewController(targetViewController, animated: true)
        }
        else {
            Player.sharedInstance.startPlayback(_playlist, position: indexPath.row)
        }
    }
}
