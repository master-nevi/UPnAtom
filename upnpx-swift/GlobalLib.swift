//
//  GlobalLib.swift
//  ControlPointDemo
//
//  Created by David Robles on 11/21/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

import Foundation

func returnIfContainsElements<T: _CollectionType>(x: T?) -> T? {
    if let x = x {
        if countElements(x) > 0 {
            return x
        }
    }
    
    return nil
}
