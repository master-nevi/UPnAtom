//
//  UniqueServiceName.swift
//  ControlPointDemo
//
//  Created by David Robles on 12/7/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

struct UniqueServiceName {
    let uuid, urn: String
    var rawValue: String {
        if let customRawValue = _customRawValue {
            return customRawValue
        }
        return "\(uuid)::\(urn)"
    }
    init(uuid: String, urn: String, customRawValue: String) {
        self.uuid = uuid
        self.urn = urn
        _customRawValue = customRawValue
    }
    init(uuid: String, urn: String) {
        self.uuid = uuid
        self.urn = urn
    }
    
    private let _customRawValue: String?
}

extension UniqueServiceName: Printable {
    var description: String {
        return rawValue
    }
}

extension UniqueServiceName: Hashable {
    var hashValue: Int {
        return uuid.hashValue ^ urn.hashValue
    }
}

func ==(lhs: UniqueServiceName, rhs: UniqueServiceName) -> Bool {
    return lhs.uuid == rhs.uuid && lhs.urn == rhs.urn
}
