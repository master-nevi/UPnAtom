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

typealias Error = NSError

enum Result<T> {
    // @autoclosure wierdness is to save us from a weird compiler error when using generic enums: http://owensd.io/2014/08/06/fixed-enum-layout.html
    case Success(@autoclosure() -> T)
    case NoContentSuccess
    case Failure(Error)
    
    init(_ value: T) {
        self = .Success(value)
    }
    
    init(_ error: NSError) {
        self = .Failure(error)
    }
    
    init() {
        self = .NoContentSuccess
    }
    
    var failed: Bool {
        switch self {
        case .Failure(let error):
            return true
            
        default:
            return false
        }
    }
    
    var error: NSError? {
        switch self {
        case .Failure(let error):
            return error
            
        default:
            return nil
        }
    }
    
    var value: T? {
        switch self {
        case .Success(let value):
            return value()
            
        default:
            return nil
        }
    }
}

func removeObject<T: Equatable>(inout arr:Array<T>, object:T) -> T? {
    if let found = find(arr,object) {
        return arr.removeAtIndex(found)
    }
    return nil
}
