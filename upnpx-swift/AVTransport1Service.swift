//
//  AVTransport1Service.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/9/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

class AVTransport1Service: AbstractUPnPService {
    
}

extension AVTransport1Service: ExtendedPrintable {
    override var className: String { return "AVTransport1Service" }
    override var description: String {
        var properties = PropertyPrinter()
        properties.add(super.className, property: super.description)
        return properties.description
    }
}
