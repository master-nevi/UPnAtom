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
            didSetRenderer(oldRenderer: oldValue, newRenderer: mediaRenderer)
        }
    }
    private(set) var playPauseButton: UIBarButtonItem! // TODO: Should ideally be a constant, see Github issue #10
    private(set) var stopButton: UIBarButtonItem! // TODO: Should ideally be a constant, see Github issue #10
    
    private var _position: Int = 0
    private var _playlist: [ContentDirectory1Object]?
    private var _avTransportEventObserver: AnyObject?
    private var _playerState: PlayerState = PlayerState.Stopped {
        didSet {
            playerStateDidChange()
        }
    }
    private var _avTransportInstanceID = "0"
    
    enum PlayerState {
        case Unknown
        case Stopped
        case Playing
        case Paused
    }
    
    init() {
        playPauseButton = UIBarButtonItem(image: UIImage(named: "play_button"), style: .Plain, target: self, action: "playPauseButtonTapped:")
        stopButton = UIBarButtonItem(image: UIImage(named: "stop_button"), style: .Plain, target: self, action: "stopButtonTapped:")
    }
    
    func startPlayback(playlist: [ContentDirectory1Object], position: Int) {
        _playlist = playlist
        
        startPlayback(position: position)
    }
    
    func startPlayback(position position: Int) {
        _position = position
        
        if let item = _playlist?[position] as? ContentDirectory1VideoItem,
            uri = item.resourceURL.absoluteString {
                let instanceID = _avTransportInstanceID
                mediaRenderer?.avTransportService?.setAVTransportURI(instanceID: instanceID, currentURI: uri, currentURIMetadata: "", success: { () -> Void in
                    println("URI set succeeded!")
                    self.play({ () -> Void in
                        println("Play command succeeded!")
                        }, failure: { (error) -> Void in
                            println("Play command failed: \(error)")
                    })
                    
                    }, failure: { (error) -> Void in
                        println("URI set failed: \(error)")
                })
        }
    }
    
    @objc private func playPauseButtonTapped(sender: AnyObject) {
        print("play/pause button tapped")
        
        switch _playerState {
        case .Playing:
            pause({ () -> Void in
                print("Pause command succeeded!")
            }, failure: { (error) -> Void in
                print("Pause command failed: \(error)")
            })
        case .Paused, .Stopped:
            play({ () -> Void in
                print("Play command succeeded!")
                }, failure: { (error) -> Void in
                    print("Play command failed: \(error)")
            })
        default:
            print("Play/pause button cannot be used in this state.")
        }
    }
    
    @objc private func stopButtonTapped(sender: AnyObject) {
        print("stop button tapped")
        
        switch _playerState {
        case .Playing, .Paused:
            stop({ () -> Void in
                print("Stop command succeeded!")
                }, failure: { (error) -> Void in
                    print("Stop command failed: \(error)")
            })
        case .Stopped:
            print("Stop button cannot be used in this state.")
        default:
            print("Stop button cannot be used in this state.")
        }
    }
    
    private func didSetRenderer(oldRenderer oldRenderer: MediaRenderer1Device?, newRenderer: MediaRenderer1Device?) {
        if let avTransportEventObserver: AnyObject = _avTransportEventObserver {
            oldRenderer?.avTransportService?.removeEventObserver(avTransportEventObserver)
        }
        
        _avTransportEventObserver = newRenderer?.avTransportService?.addEventObserver(NSOperationQueue.currentQueue(), callBackBlock: { (event: UPnPEvent) -> Void in
            if let avTransportEvent = event as? AVTransport1Event,
                transportState = (avTransportEvent.instanceState["TransportState"] as? String)?.lowercaseString {
                    println("\(event.service?.className) Event: \(avTransportEvent.instanceState)")
                    println("transport state: \(transportState)")
                    if transportState.rangeOfString("playing") != nil {
                        self._playerState = .Playing
                    }
                    else if transportState.rangeOfString("paused") != nil {
                        self._playerState = .Paused
                    }
                    else if transportState.rangeOfString("stopped") != nil {
                        self._playerState = .Stopped
                    }
                    else {
                        self._playerState = .Unknown
                    }
            }
        })
    }
    
    private func playerStateDidChange() {
        switch _playerState {
        case .Stopped:
            playPauseButton.image = UIImage(named: "play_button")
        case .Playing:
            playPauseButton.image = UIImage(named: "pause_button")
        case .Paused:
            playPauseButton.image = UIImage(named: "play_button")
        case .Unknown:
            playPauseButton.image = UIImage(named: "play_button")
        }
    }
    
    private func play(success: () -> Void, failure:(error: NSError) -> Void) {
        self.mediaRenderer?.avTransportService?.play(instanceID: _avTransportInstanceID, speed: "1", success: success, failure: failure)
    }
    
    private func pause(success: () -> Void, failure:(error: NSError) -> Void) {
        self.mediaRenderer?.avTransportService?.pause(instanceID: _avTransportInstanceID, success: success, failure: failure)
    }
    
    private func stop(success: () -> Void, failure:(error: NSError) -> Void) {
        self.mediaRenderer?.avTransportService?.stop(instanceID: _avTransportInstanceID, success: success, failure: failure)
    }
}
