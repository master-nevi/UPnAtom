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

func curlRep(_ request: URLRequest) -> String {
    var curl = ""
    
    curl += "curl -i"
    
    if let httpMethod = request.httpMethod {
        curl += " -X \(httpMethod)"
    }
    
    if let httpBody = request.httpBody,
        let body = NSString(data: httpBody, encoding: String.Encoding.utf8.rawValue) {
            curl += " -d '"
            curl += "\(body)"
            curl += "'"
    }
    
    if let allHTTPHeaderFields = request.allHTTPHeaderFields {
        for (key, value) in allHTTPHeaderFields {
            curl += " -H '\(key): \(value)'"
        }
    }
    
    curl += " \"\(request.url)\""
    
    return curl
}

public typealias Error = NSError

public enum Result<T> {
    case success(T)
    case failure(Error)
    
    init(_ value: T) {
        self = .success(value)
    }
    
    init(_ error: Error) {
        self = .failure(error)
    }
    
    var failed: Bool {
        if case .failure(_) = self {
            return true
        }
        return false
    }
    
    var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
    
    var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
}

public enum EmptyResult {
    case success
    case failure(Error)
    
    init() {
        self = .success
    }
    
    init(_ error: Error) {
        self = .failure(error)
    }
    
    var failed: Bool {
        if case .failure(_) = self {
            return true
        }
        return false
    }
    
    var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

func createError(_ message: String) -> Error {
    return NSError(domain: "UPnAtom", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
}

extension RangeReplaceableCollection where Iterator.Element : Equatable {
    mutating func removeObject(_ object: Iterator.Element) -> Iterator.Element? {
        if let found = self.index(of: object) {
            return remove(at: found)
        }
        return nil
    }
}

extension NSError {
    /// An alternative to iOS's [NSError localizedDescription] which returns an esoteric Cocoa error when [NSError userInfo][NSLocalizedDescriptionKey] is nil. In that case, this method will return nil instead.
    var localizedDescriptionOrNil: String? {
        return self.userInfo[NSLocalizedDescriptionKey] as? String
    }
    
    func localizedDescription(_ defaultDescription: String) -> String {
        return self.localizedDescriptionOrNil != nil ? self.localizedDescriptionOrNil! : defaultDescription
    }
}

/// Until Apple provides modules for all of the missing C libraries, there's no good way to perform this task in Swift.
//func getIFAddresses() -> [String: String] {
//    var addresses = [String: String]()
//    
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
//    
//    return addresses
//}

extension Timer {
    fileprivate class NSTimerClosureHandler {
        var closure: () -> Void
        
        init(closure: @escaping () -> Void) {
            self.closure = closure
        }
        
        dynamic func fire() {
            closure()
        }
    }
    
    convenience init(timeInterval: TimeInterval, repeats: Bool, closure: @escaping (() -> Void)) {
        let closureHandler = NSTimerClosureHandler(closure: closure)
        self.init(timeInterval: timeInterval, target: closureHandler, selector: #selector(NSTimerClosureHandler.fire), userInfo: nil, repeats: repeats)
    }
    
    class func scheduledTimerWithTimeInterval(_ timeInterval: TimeInterval, repeats: Bool, closure: @escaping (() -> Void)) -> Timer {
        let closureHandler = NSTimerClosureHandler(closure: closure)
        return self.scheduledTimer(timeInterval: timeInterval, target: closureHandler, selector: #selector(NSTimerClosureHandler.fire), userInfo: nil, repeats: repeats)
    }
}

extension NSArray {
    func firstUsingPredicate<T>(_ predicate: NSPredicate) -> T? {
        return self.filtered(using: predicate).first as? T
    }
}

extension UUID {
    var dashlessUUIDString: String {
        return self.uuidString.replacingOccurrences(of: "-", with: "", options: .literal)
    }
}

struct Stack<T> {
    var elements = [T]()
    
    mutating func push(_ element: T) {
        elements.append(element)
    }
    
    mutating func pop() -> T {
        return elements.removeLast()
    }
    
    func peek() -> T? {
        return elements.last
    }
    
    func isEmpty() -> Bool {
        return elements.isEmpty
    }
}

func +<K,V> (left: Dictionary<K,V>, right: Dictionary<K,V>) -> Dictionary<K,V> {
    var result = Dictionary<K,V>()
    
    for (k, v) in left {
        result[k] = v
    }
    
    for (k, v) in right {
        result[k] = v
    }
    
    return result
}

func +=<K,V> (left: inout Dictionary<K,V>, right: Dictionary<K,V>) {
    for (k, v) in right {
        left[k] = v
    }
}
