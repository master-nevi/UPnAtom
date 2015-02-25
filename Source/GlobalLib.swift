//
//  GlobalLib.swift
//
//  Copyright (c) 2015 David Robles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import NetworkTools

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
    
/* 
Until Apple provides modules for all of the missing C libraries, there's no good way to perform this task in Swift. Commenting out the pure Swift version and calling into Obj-C.
*/
//    // Get list of all interfaces on the local machine:
//    var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
//    if getifaddrs(&ifaddr) == 0 {
//        
//        // For each interface ...
//        for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
//            let flags = Int32(ptr.memory.ifa_flags)
//            var addr = ptr.memory.ifa_addr.memory
//            let interfaceName = String.fromCString(ptr.memory.ifa_name)
//            
//            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
//            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
//                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
//                    
//                    // Convert interface address to a human readable string:
//                    var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
//                    if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
//                        nil, socklen_t(0), NI_NUMERICHOST) == 0) {
//                            let address = String.fromCString(hostname)
//                            if address != nil && interfaceName != nil {
//                                addresses[interfaceName!] = address!
//                            }
//                    }
//                }
//            }
//        }
//        freeifaddrs(ifaddr)
//    }
    
    let addressesFromObjc = NetworkTools.getIFAddresses()
    for (key, value) in addressesFromObjc {
        let interfaceName: String? = key as? String
        let address: String? = value as? String
        addresses[interfaceName!] = address!
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