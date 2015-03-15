//
//  Player.swift
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
import UPnAtom

private let _PlayerSharedInstance = Player()

class Player {
    class var sharedInstance: Player {
        return _PlayerSharedInstance
    }
    var mediaServer: MediaServer1Device?
    var mediaRenderer: MediaRenderer1Device? {
        didSet {
            didSetRenderer(mediaRenderer)
        }
    }
    
    private var _position: Int = 0
    private var _playlist: [ContentDirectory1Object]?
    
    init() { }
    
    func play(playlist: [ContentDirectory1Object], position: Int) {
        _playlist = playlist
        
        play(position: position)
    }
    
    func play(#position: Int) {
        _position = position
        
        if let item = _playlist?[position] as? ContentDirectory1VideoItem {
            if let uri = item.resourceURL.absoluteString {
                let instanceID = "0"
                mediaRenderer?.avTransportService()?.setAVTransportURI(instanceID: instanceID, currentURI: uri, currentURIMetadata: "", success: { () -> Void in
                    println("URI set succeeded!")
                    
                    self.mediaRenderer?.avTransportService()?.play(instanceID: instanceID, speed: "1", success: { () -> Void in
                        println("Play command succeeded!")
                        }, failure: { (error) -> Void in
                            println("Play command failed: \(error)")
                    })
                    }, failure: { (error) -> Void in
                        println("URI set failed: \(error)")
                })
            }
        }
    }
    
    private func didSetRenderer(renderer: MediaRenderer1Device?) {
        if let renderer = renderer {
            renderer.avTransportService()?.addEventObserver(NSOperationQueue.currentQueue(), callBackBlock: { (event: UPnPEvent) -> Void in
                if let avTransportEvent = event as? AVTransport1Event {
                    println("\(event.service?.className) Event: \(avTransportEvent.instanceState)")
                }
            })
        }
    }
}
