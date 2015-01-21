//
//  ConnectionManager1Service.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/9/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class ConnectionManager1Service: AbstractUPnPService {
    
}

extension ConnectionManager1Service: ExtendedPrintable {
    override var className: String { return "ConnectionManager1Service" }
    override var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
