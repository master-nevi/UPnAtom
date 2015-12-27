//
//  Player.m
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

#import "Player.h"
@import UPnAtom;

typedef NS_ENUM(NSInteger, PlayerState) {
    PlayerStateUnknown = 0,
    PlayerStateStopped,
    PlayerStatePlaying,
    PlayerStatePaused
};

@interface Player ()
@property (nonatomic, readwrite) NSArray *playlist;
@property (nonatomic, readwrite) UIBarButtonItem *playPauseButton;
@property (nonatomic, readwrite) UIBarButtonItem *stopButton;
@property (nonatomic) PlayerState playerState;
@end

@implementation Player {
    NSInteger _position;
    id _avTransportEventObserver;
    NSString *_avTransportInstanceID;
}

+ (Player *)sharedInstance {
    static Player *instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [Player new];
        
        instance.playPauseButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"play_button"] style:UIBarButtonItemStylePlain target:instance action:@selector(playPauseButtonTapped:)];
        instance.stopButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"stop_button"] style:UIBarButtonItemStylePlain target:instance action:@selector(stopButtonTapped:)];
        instance->_avTransportInstanceID = @"0";
    });
    
    return instance;
}

- (void)setMediaRenderer:(MediaRenderer1Device *)mediaRenderer {
    MediaRenderer1Device *oldRenderer = _mediaRenderer;
    _mediaRenderer = mediaRenderer;
    
    if (_avTransportEventObserver != nil) {
        [oldRenderer.avTransportService removeEventObserver:_avTransportEventObserver];
    }
    
    _avTransportEventObserver = [mediaRenderer.avTransportService addEventObserver:[NSOperationQueue currentQueue] callBackBlock:^(UPnPEvent *event) {
        if ([event.service isAVTransport1Service] && [event isAVTransport1Event]) {
            AVTransport1Event *avTransportEvent = (AVTransport1Event *)event;
            NSLog(@"%@ Event: %@", event.service.className, avTransportEvent.instanceState);
            NSString *transportState = [avTransportEvent.instanceState[@"TransportState"] lowercaseString];
            if (transportState.length) {
                if ([transportState rangeOfString:@"playing"].location != NSNotFound) {
                    self.playerState = PlayerStatePlaying;
                }
                else if ([transportState rangeOfString:@"paused"].location != NSNotFound) {
                    self.playerState = PlayerStatePaused;
                }
                else if ([transportState rangeOfString:@"stopped"].location != NSNotFound) {
                    self.playerState = PlayerStateStopped;
                }
                else {
                    self.playerState = PlayerStateUnknown;
                }
            }
        }
    }];
}

- (void)startPlayback:(NSArray *)playList position:(NSInteger)position{
    [self setPlaylist:playList];
    
    [self startPlayback:position];
}

- (void)startPlayback:(NSInteger)position{
    //Do we have a Renderer & a playlist ?
    if(_mediaRenderer == nil || _playlist == nil){
        return;
    }
    
    if(position >= [_playlist count]){
        position = 0; //Loop
    }
    
    _position = position;

    ContentDirectory1Object *item = _playlist[position];
    //Is it a Media1ServerItem ?
    if([item isContentDirectory1VideoItem]){
        ContentDirectory1VideoItem *item = _playlist[position];
        
        NSString *uri = [item resourceURL].absoluteString;
        if (uri.length) {
            __weak typeof(self) weakSelf = self;
            [self.mediaRenderer.avTransportService setAVTransportURIWithInstanceID:_avTransportInstanceID currentURI:uri currentURIMetadata:@"" success:^{
                NSLog(@"URI Set succeeded!");
                
                [weakSelf playWithSuccess:^{
                    NSLog(@"Play command succeeded!");
                } failure:^(NSError *error) {
                    NSLog(@"Play command failed: %@", error.localizedDescription);
                }];
            } failure:^(NSError *error) {
                NSLog(@"URI Set failed: %@", error.localizedDescription);
            }];
        }
    }
}

#pragma mark - Internal lib

- (void)playPauseButtonTapped:(id)sender {
    switch (self.playerState) {
        case PlayerStatePlaying:
            [self pauseWithSuccess:^{
                NSLog(@"Pause command succeeded!");
            } failure:^(NSError *error) {
                NSLog(@"Pause command failed: %@", error.localizedDescription);
            }];
            break;
            
        case PlayerStatePaused:
            [self playWithSuccess:^{
                NSLog(@"Play command succeeded!");
            } failure:^(NSError *error) {
                NSLog(@"Play command failed: %@", error.localizedDescription);
            }];
            break;
            
        case PlayerStateStopped:
            [self playWithSuccess:^{
                NSLog(@"Play command succeeded!");
            } failure:^(NSError *error) {
                NSLog(@"Play command failed: %@", error.localizedDescription);
            }];
            break;
            
        default:
            NSLog(@"Play/Pause button cannot be used in this state.");
            break;
    }
}

- (void)stopButtonTapped:(id)sender {
    switch (self.playerState) {
        case PlayerStatePlaying:
            [self stopWithSuccess:^{
                NSLog(@"Stop command succeeded!");
            } failure:^(NSError *error) {
                NSLog(@"Stop command failed: %@", error.localizedDescription);
            }];
            break;
            
        case PlayerStatePaused:
            [self stopWithSuccess:^{
                NSLog(@"Stop command succeeded!");
            } failure:^(NSError *error) {
                NSLog(@"Stop command failed: %@", error.localizedDescription);
            }];
            break;
            
        case PlayerStateStopped:
            NSLog(@"Stop button cannot be used in this state.");
            break;
            
        default:
            NSLog(@"Stop button cannot be used in this state.");
            break;
    }
}

- (void)setPlayerState:(PlayerState)playerState {
    _playerState = playerState;
    
    switch (playerState) {
        case PlayerStateStopped:
            self.playPauseButton.image = [UIImage imageNamed:@"play_button"];
            break;
            
        case PlayerStatePlaying:
            self.playPauseButton.image = [UIImage imageNamed:@"pause_button"];
            break;
            
        case PlayerStatePaused:
            self.playPauseButton.image = [UIImage imageNamed:@"play_button"];
            break;
            
        default:
            self.playPauseButton.image = [UIImage imageNamed:@"play_button"];
            break;
    }
}

- (void)playWithSuccess:(void (^)(void))success failure:(void (^)(NSError *))failure {
    [self.mediaRenderer.avTransportService playWithInstanceID:_avTransportInstanceID speed:@"1" success:success failure:failure];
}

- (void)pauseWithSuccess:(void (^)(void))success failure:(void (^)(NSError *))failure {
    [self.mediaRenderer.avTransportService pauseWithInstanceID:_avTransportInstanceID success:success failure:failure];
}

- (void)stopWithSuccess:(void (^)(void))success failure:(void (^)(NSError *))failure {
    [self.mediaRenderer.avTransportService stopWithInstanceID:_avTransportInstanceID success:success failure:failure];
}

@end
