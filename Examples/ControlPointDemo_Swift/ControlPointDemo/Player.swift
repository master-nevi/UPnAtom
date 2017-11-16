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
    fileprivate(set) var playPauseButton: UIBarButtonItem! // TODO: Should ideally be a constant, see Github issue #10
    fileprivate(set) var stopButton: UIBarButtonItem! // TODO: Should ideally be a constant, see Github issue #10
    
    fileprivate var _position: Int = 0
    fileprivate var _playlist: [ContentDirectory1Object]?
    fileprivate var _avTransportEventObserver: AnyObject?
    fileprivate var _playerState: PlayerState = PlayerState.stopped {
        didSet {
            playerStateDidChange()
        }
    }
    fileprivate var _avTransportInstanceID = "0"
    
    enum PlayerState {
        case unknown
        case stopped
        case playing
        case paused
    }
    
    init() {
        playPauseButton = UIBarButtonItem(image: UIImage(named: "play_button"), style: .plain, target: self, action: #selector(Player.playPauseButtonTapped(_:)))
        stopButton = UIBarButtonItem(image: UIImage(named: "stop_button"), style: .plain, target: self, action: #selector(Player.stopButtonTapped(_:)))
    }
    
    func startPlayback(_ playlist: [ContentDirectory1Object], position: Int) {
        _playlist = playlist
        
        startPlayback(position: position)
    }
    
    func startPlayback(position: Int) {
        _position = position
        
        if let item = _playlist?[position] as? ContentDirectory1VideoItem {
            let uri = item.resourceURL.absoluteString
            let instanceID = _avTransportInstanceID
            mediaRenderer?.avTransportService?.setAVTransportURI(instanceID: instanceID, currentURI: uri, currentURIMetadata: "", success: { () -> Void in
                print("URI set succeeded!")
                self.play({ () -> Void in
                    print("Play command succeeded!")
                    }, failure: { (error) -> Void in
                        print("Play command failed: \(error)")
                })
                
                }, failure: { (error) -> Void in
                    print("URI set failed: \(error)")
            })
        }
    }
    
    @objc fileprivate func playPauseButtonTapped(_ sender: AnyObject) {
        print("play/pause button tapped")
        
        switch _playerState {
        case .playing:
            pause({ () -> Void in
                print("Pause command succeeded!")
            }, failure: { (error) -> Void in
                print("Pause command failed: \(error)")
            })
        case .paused, .stopped:
            play({ () -> Void in
                print("Play command succeeded!")
                }, failure: { (error) -> Void in
                    print("Play command failed: \(error)")
            })
        default:
            print("Play/pause button cannot be used in this state.")
        }
    }
    
    @objc fileprivate func stopButtonTapped(_ sender: AnyObject) {
        print("stop button tapped")
        
        switch _playerState {
        case .playing, .paused:
            stop({ () -> Void in
                print("Stop command succeeded!")
                }, failure: { (error) -> Void in
                    print("Stop command failed: \(error)")
            })
        case .stopped:
            print("Stop button cannot be used in this state.")
        default:
            print("Stop button cannot be used in this state.")
        }
    }
    
    fileprivate func didSetRenderer(oldRenderer: MediaRenderer1Device?, newRenderer: MediaRenderer1Device?) {
        if let avTransportEventObserver: AnyObject = _avTransportEventObserver {
            oldRenderer?.avTransportService?.removeEventObserver(avTransportEventObserver)
        }
        
        _avTransportEventObserver = newRenderer?.avTransportService?.addEventObserver(OperationQueue.current, callBackBlock: { (event: UPnPEvent) -> Void in
            if let avTransportEvent = event as? AVTransport1Event,
                let transportState = (avTransportEvent.instanceState["TransportState"] as? String)?.lowercased() {
                    print("\(String(describing: event.service?.className)) Event: \(avTransportEvent.instanceState)")
                    print("transport state: \(transportState)")
                    if transportState.range(of: "playing") != nil {
                        self._playerState = .playing
                    }
                    else if transportState.range(of:"paused") != nil {
                        self._playerState = .paused
                    }
                    else if transportState.range(of:"stopped") != nil {
                        self._playerState = .stopped
                    }
                    else {
                        self._playerState = .unknown
                    }
            }
        })
    }
    
    fileprivate func playerStateDidChange() {
        switch _playerState {
        case .stopped, .paused, .unknown:
            playPauseButton.image = UIImage(named: "play_button")
        case .playing:
            playPauseButton.image = UIImage(named: "pause_button")
        }
    }
    
    fileprivate func play(_ success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        self.mediaRenderer?.avTransportService?.play(instanceID: _avTransportInstanceID, speed: "1", success: success, failure: failure)
    }
    
    fileprivate func pause(_ success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        self.mediaRenderer?.avTransportService?.pause(instanceID: _avTransportInstanceID, success: success, failure: failure)
    }
    
    fileprivate func stop(_ success: @escaping () -> Void, failure:@escaping (_ error: NSError) -> Void) {
        self.mediaRenderer?.avTransportService?.stop(instanceID: _avTransportInstanceID, success: success, failure: failure)
    }
}
