//
//  UPnPManager.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/21/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

private let _UPnPManagerSharedInstance = UPnPManager_Swift()

@objc class UPnPManager_Swift {
    class var sharedInstance: UPnPManager_Swift {
        return _UPnPManagerSharedInstance
    }
    let ssdp = SSDPDB_ObjC()
    let upnpDB: UPnPDB_Swift
    
    init() {
        upnpDB = UPnPDB_Swift(ssdpDB: ssdp)
    }
}
