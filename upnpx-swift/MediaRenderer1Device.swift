//
//  MediaRenderer1Device.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/19/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class MediaRenderer1Device_Swift: AbstractUPnPDevice_Swift {
    override var className: String { return "MediaRenderer1Device_Swift" }
    override var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)        
        return properties.description
    }
}
