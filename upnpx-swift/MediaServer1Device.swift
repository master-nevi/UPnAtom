//
//  MediaServer1Device.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class MediaServer1Device_Swift: AbstractUPnPDevice_Swift {
    override var className: String { return "MediaServer1Device_Swift" }
    override var description: String {
        var properties = [String: String]()
        properties[super.className] = super.description.stringByReplacingOccurrencesOfString("\n", replacement: "\n\t")
        
        return objectDescription(properties)
    }
}
