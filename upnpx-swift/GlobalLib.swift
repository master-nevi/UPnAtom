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

func curlRep(request: NSURLRequest) -> String {
    var curl = ""
    
    curl += "curl -i"
    
    if let httpMethod = request.HTTPMethod {
        curl += " -X \(httpMethod)"
    }
    
    if let httpBody = request.HTTPBody {
        if let body = NSString(data: httpBody, encoding: NSUTF8StringEncoding) {
            curl += " -d '"
            curl += "\(body)"
            curl += "'"
        }
    }
    
    for (key, value) in request.allHTTPHeaderFields as [String: AnyObject] {
        curl += " -H '\(key): \(value)'"
    }
    
    curl += " \"\(request.URL)\""
    
    return curl
}
