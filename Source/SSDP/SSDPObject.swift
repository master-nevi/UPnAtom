//
//  AVTransport1Event.swift
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

import UIKit

enum SSDPNotificationType {
    case RootDevice
    case UUID
    case Device
    case Service
    case Unknown
    
    init(notificationType: String) {
        println("Notification type: \(notificationType)")
        if notificationType == "upnp:rootdevice" {
            self = .RootDevice
        }
        else if notificationType.rangeOfString("uuid:") != nil {
            self = .UUID
        }
        else if notificationType.rangeOfString(":device:") != nil {
            self = .Device
        }
        else if notificationType.rangeOfString(":service:") != nil {
            self = .Service
        }
        
        self = .Unknown
    }
}

struct SSDPObject {
    let uuid: String
    let urn: String?
    let usn: String
    let xmlLocation: NSURL
    let notificationType: SSDPNotificationType
}

extension SSDPObject: Equatable { }

func ==(lhs: SSDPObject, rhs: SSDPObject) -> Bool {
    return lhs.usn == rhs.usn
}
