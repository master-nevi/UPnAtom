//
//  RenderingControl1Service.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/9/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class RenderingControl1Service_Swift: AbstractUPnPService_Swift {
    override var className: String { return "RenderingControl1Service_Swift" }
    override var description: String {
        var properties = [String: String]()
        properties[super.className] = super.description.stringByReplacingOccurrencesOfString("\n", replacement: "\n\t")
        
        return stringDictionaryDescription(properties)
    }
}
