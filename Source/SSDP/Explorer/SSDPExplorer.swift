//
//  SSDPExplorer.swift
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
import CocoaAsyncSocket
import AFNetworking

protocol SSDPExplorerDelegate: class {
    func ssdpExplorer(_ explorer: SSDPExplorer, didMakeDiscovery discovery: SSDPDiscovery)
    // Removed discoveries will have an invalid desciption URL
    func ssdpExplorer(_ explorer: SSDPExplorer, didRemoveDiscovery discovery: SSDPDiscovery)    
    /// Assume explorer has stopped after a failure.
    func ssdpExplorer(_ explorer: SSDPExplorer, didFailWithError error: NSError)
}

class SSDPExplorer {
    enum SSDPMessageType {
        case searchResponse
        case availableNotification
        case updateNotification
        case unavailableNotification
    }
    
    weak var delegate: SSDPExplorerDelegate?
    
    // private
    fileprivate static let _multicastGroupAddress = "239.255.255.250"
    fileprivate static let _multicastUDPPort: UInt16 = 1900
    fileprivate var _multicastSocket: GCDAsyncUdpSocket? // TODO: Should ideally be a constant, see Github issue #10
    fileprivate var _unicastSocket: GCDAsyncUdpSocket? // TODO: Should ideally be a constant, see Github issue #10
    fileprivate var _types = [SSDPType]() // TODO: Should ideally be a Set<SSDPType>, see Github issue #13
    
    func startExploring(forTypes types: [SSDPType], onInterface interface: String = "en0") -> EmptyResult {
        assert(_multicastSocket == nil, "Socket is already open, stop it first!")
        
        // create sockets
        guard let multicastSocket: GCDAsyncUdpSocket? = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main),
            let unicastSocket: GCDAsyncUdpSocket? = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main) else {
                return .failure(createError("Socket could not be created"))
        }
        try? multicastSocket?.enableBroadcast(true)
        try? multicastSocket?.enableReusePort(true)
        _multicastSocket = multicastSocket
        _unicastSocket = unicastSocket
        multicastSocket?.setIPv6Enabled(false)
        unicastSocket?.setIPv6Enabled(false)
        
        // Configure unicast socket
        // Bind to address on the specified interface to a random port to receive unicast datagrams
        do {
            try unicastSocket?.bind(toPort: 0, interface: interface)
        } catch {
            stopExploring()
            return .failure(createError("Could not bind socket to port"))
        }
        
        do {
            try unicastSocket?.beginReceiving()
        } catch {
            stopExploring()
            return .failure(createError("Could not begin receiving error"))
        }
        
        // Configure multicast socket
        // Bind to port without defining the interface to bind to the address INADDR_ANY (0.0.0.0). This prevents any address filtering which allows datagrams sent to the multicast group to be receives
        do {
            try multicastSocket?.bind(toPort: SSDPExplorer._multicastUDPPort)
        } catch {
            stopExploring()
            return .failure(createError("Could not bind socket to multicast port"))
        }
        
        // Join multicast group to express interest to router of receiving multicast datagrams
        do {
            try multicastSocket?.joinMulticastGroup(SSDPExplorer._multicastGroupAddress)
        } catch {
            stopExploring()
            return .failure(createError("Could not join multicast group"))
        }
        
        do {
            try multicastSocket?.beginReceiving()
        } catch {
            stopExploring()
            return .failure(createError("Could not begin receiving error"))
        }
        
        _types = types
        for type in types {
            if let data = searchRequestData(forType: type) {
//                println(">>>> SENDING SEARCH REQUEST\n\(NSString(data: data, encoding: NSUTF8StringEncoding))")
                unicastSocket?.send(data, toHost: SSDPExplorer._multicastGroupAddress, port: SSDPExplorer._multicastUDPPort, withTimeout: -1, tag: type.hashValue)
            }
        }
        
        return .success
    }
    
    func stopExploring() {
        _multicastSocket?.close()
        _multicastSocket = nil
        _unicastSocket?.close()
        _unicastSocket = nil
        _types = []
    }
    
    fileprivate func searchRequestData(forType type: SSDPType) -> Data? {
        var requestBody = [
            "M-SEARCH * HTTP/1.1",
            "HOST: \(SSDPExplorer._multicastGroupAddress):\(SSDPExplorer._multicastUDPPort)",
            "MAN: \"ssdp:discover\"",
            "ST: \(type.rawValue)",
            "MX: 3"]
        
        if let userAgent = AFHTTPRequestSerializer().value(forHTTPHeaderField: "User-Agent") {
            requestBody += ["USER-AGENT: \(userAgent)\r\n\r\n\r\n"]
        }
        
        let requestBodyString = requestBody.joined(separator: "\r\n")
        return requestBodyString.data(using: String.Encoding.utf8, allowLossyConversion: false)
    }
    
    fileprivate func notifyDelegate(ofFailure error: NSError) {
        DispatchQueue.main.async(execute: { [unowned self] () -> Void in
            self.delegate?.ssdpExplorer(self, didFailWithError: error)
        })
    }
    
    fileprivate func notifyDelegate(_ discovery: SSDPDiscovery, added: Bool) {
        DispatchQueue.main.async(execute: { [unowned self] () -> Void in
            added ? self.delegate?.ssdpExplorer(self, didMakeDiscovery: discovery) : self.delegate?.ssdpExplorer(self, didRemoveDiscovery: discovery)
            })
    }
    
    fileprivate func handleSSDPMessage(_ messageType: SSDPMessageType, headers: [String: String]) {
        if let usnRawValue = headers["usn"],
            let usn = UniqueServiceName(rawValue: usnRawValue),
            let locationString = headers["location"],
            let locationURL = URL(string: locationString),
            /// NT = Notification Type - SSDP discovered from device advertisements
            /// ST = Search Target - SSDP discovered as a result of using M-SEARCH requests
            let ssdpTypeRawValue = (headers["st"] != nil ? headers["st"] : headers["nt"]),
            let ssdpType = SSDPType(rawValue: ssdpTypeRawValue), _types.index(of: ssdpType) != nil {
                LogVerbose("SSDP response headers: \(headers)")
                let discovery = SSDPDiscovery(usn: usn, descriptionURL: locationURL, type: ssdpType)
                switch messageType {
                case .searchResponse, .availableNotification, .updateNotification:
                    notifyDelegate(discovery, added: true)
                case .unavailableNotification:
                    notifyDelegate(discovery, added: false)
                }
        }
    }
}

extension SSDPExplorer: GCDAsyncUdpSocketDelegate {
    @objc func udpSocket(_ sock: GCDAsyncUdpSocket!, didNotSendDataWithTag tag: Int, dueToError error: NSError!) {
        stopExploring()
        
        // this case should always have an error
        notifyDelegate(ofFailure: error ?? createError("Did not send SSDP message."))
    }
    
    @objc func udpSocketDidClose(_ sock: GCDAsyncUdpSocket!, withError error: NSError!) {
        if let error = error {
            notifyDelegate(ofFailure: error)
        }
    }
    
    @objc func udpSocket(_ sock: GCDAsyncUdpSocket!, didReceive data: Data!, fromAddress address: Data!, withFilterContext filterContext: Any!) {
        if let message = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
//            println({ () -> String in
//                let socketType = (sock === self._unicastSocket) ? "UNICAST" : "MULTICAST"
//                return "<<<< RECEIVED ON \(socketType) SOCKET\n\(message)"
//            }())
            var httpMethodLine: String?
            var headers = [String: String]()
            let headersRegularExpression = try? NSRegularExpression(pattern: "^([a-z0-9-]+): *(.+)$", options: [.caseInsensitive, .anchorsMatchLines])
            message.enumerateLines(invoking: { (line, stop) -> () in
                if httpMethodLine == nil {
                    httpMethodLine = line
                } else {
                    headersRegularExpression?.enumerateMatches(in: line, options: [], range: NSRange(location: 0, length: line.characters.count), using: { (resultOptional: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                        if let result = resultOptional, result.numberOfRanges == 3 {
                            let key = (line as NSString).substring(with: result.range(at: 1)).lowercased()
                            let value = (line as NSString).substring(with: result.range(at: 2))
                            headers[key] = value
                        }
                    })
                }
            })
            
            if let httpMethodLine = httpMethodLine {
                let nts = headers["nts"]
                switch (httpMethodLine, nts) {
                case ("HTTP/1.1 200 OK", _):
                    handleSSDPMessage(.searchResponse, headers: headers)
                case ("NOTIFY * HTTP/1.1", .some(let notificationType)) where notificationType == "ssdp:alive":
                    handleSSDPMessage(.availableNotification, headers: headers)
                case ("NOTIFY * HTTP/1.1", .some(let notificationType)) where notificationType == "ssdp:update":
                    handleSSDPMessage(.updateNotification, headers: headers)
                case ("NOTIFY * HTTP/1.1", .some(let notificationType)) where notificationType == "ssdp:byebye":
                    headers["location"] = headers["host"] // byebye messages don't have a location
                    handleSSDPMessage(.unavailableNotification, headers: headers)
                default:
                    return
                }
            }
        }
    }
}
