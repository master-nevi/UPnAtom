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
    case Failure(Error)
    
    init(_ value: T) {
        self = .Success(value)
    }
    
    init(_ error: Error) {
        self = .Failure(error)
    }
        
    var failed: Bool {
        switch self {
        case .Failure(let error):
            return true
            
        default:
            return false
        }
    }
    
    var error: Error? {
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

enum EmptyResult {
    case Success
    case Failure(Error)
    
    init() {
        self = .Success
    }
    
    init(_ error: Error) {
        self = .Failure(error)
    }
    
    var failed: Bool {
        switch self {
        case .Failure(let error):
            return true
            
        default:
            return false
        }
    }
    
    var error: Error? {
        switch self {
        case .Failure(let error):
            return error
            
        default:
            return nil
        }
    }
}

func createError(message: String) -> Error {
    return NSError(domain: "UPnAtom", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
}

func removeObject<T: Equatable>(inout arr:Array<T>, object:T) -> T? {
    if let found = find(arr,object) {
        return arr.removeAtIndex(found)
    }
    return nil
}

extension NSError {
    /// An alternative to iOS's [NSError localizedDescription] which returns an esoteric Cocoa error when [NSError userInfo][NSLocalizedDescriptionKey] is nil. In that case, this method will return nil instead.
    var localizedDescriptionOrNil: String? {
        return self.userInfo?[NSLocalizedDescriptionKey] as? String
    }
    
    func localizedDescription(defaultDescription: String) -> String {
        return self.localizedDescriptionOrNil != nil ? self.localizedDescriptionOrNil! : defaultDescription
    }
}

func getIFAddresses() -> [String: String] {
    var addresses = [String: String]()
    
    // Get list of all interfaces on the local machine:
    var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
    if getifaddrs(&ifaddr) == 0 {
        
        // For each interface ...
        for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
            let flags = Int32(ptr.memory.ifa_flags)
            var addr = ptr.memory.ifa_addr.memory
            let interfaceName = String.fromCString(ptr.memory.ifa_name)
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                    if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                        nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            let address = String.fromCString(hostname)
                            if address != nil && interfaceName != nil {
                                addresses[interfaceName!] = address!
                            }
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
    }
    
    return addresses
}

extension NSTimer {
    private class NSTimerClosureHandler {
        var closure: () -> Void
        
        init(closure: () -> Void) {
            self.closure = closure
        }
        
        dynamic func fire() {
            closure()
        }
    }
    
    convenience init(timeInterval: NSTimeInterval, repeats: Bool, closure: (() -> Void)) {
        let closureHandler = NSTimerClosureHandler(closure: closure)
        self.init(timeInterval: timeInterval, target: closureHandler, selector: "fire", userInfo: nil, repeats: repeats)
    }
    
    class func scheduledTimerWithTimeInterval(timeInterval: NSTimeInterval, repeats: Bool, closure: (() -> Void)) -> NSTimer {
        let closureHandler = NSTimerClosureHandler(closure: closure)
        return self.scheduledTimerWithTimeInterval(timeInterval, target: closureHandler, selector: "fire", userInfo: nil, repeats: repeats)
    }
}
