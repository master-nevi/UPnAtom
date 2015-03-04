//
//  PlayBack.m
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

#import "PlayBack.h"
#import "NSString+UPnPExtentions.h"
#import <UPnAtom/UPnAtom-Swift.h>

static PlayBack *_playback = nil;

@implementation PlayBack

@synthesize renderer;
@synthesize server;
@synthesize playlist;
@synthesize atomRenderer = _atomRenderer;
@synthesize atomServer;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        pos = 0;
        renderer = nil;
        server = nil;
    }
    
    return self;
}


+(PlayBack*)GetInstance{
	if(_playback == nil){
		_playback = [[PlayBack alloc] init];
	}
	return _playback;
}

-(void)setRenderer:(MediaRenderer1Device*)rend{
    
//    MediaRenderer1Device* old = renderer;
    
    //Remove the Old Observer, if any
//    if(old!=nil){
//         if([[old avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == YES){
//             [[old avTransportService] removeObserver:(BasicUPnPServiceObserver*)self]; 
//         }
//    }

    renderer = rend;

    //Add New Observer, if any
//    if(renderer!=nil){
//        if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO){
//            [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self]; 
//        }
//    }
    
    
}

- (void)setAtomRenderer:(AbstractUPnPDevice *)atomRenderer {
    _atomRenderer = atomRenderer;
    
    MediaRenderer1Device_Swift *aRenderer = (MediaRenderer1Device_Swift *)self.atomRenderer;
    [[aRenderer avTransportService] addEventObserver:[NSOperationQueue currentQueue] callBackBlock:^(UPnPEvent *event) {
        NSLog(@"Event: %@", [[NSString alloc] initWithData:event.eventXML encoding:NSUTF8StringEncoding]);
    }];
}

-(int)Play:(NSMutableArray*)playList position:(NSInteger)position{
    [self setPlaylist:playList];
    
    //Lazy Observer attach
//    if([[renderer avTransportService] isObserver:(BasicUPnPServiceObserver*)self] == NO){
//        [[renderer avTransportService] addObserver:(BasicUPnPServiceObserver*)self]; 
//    }
    
    //Play
    return [self Play:position];
}


-(int)Play:(NSInteger)position{
    //Do we have a Renderer & a playlist ?
    if(renderer == nil || playlist == nil){
        return -1;
    }
    
    if(position >= [playlist count]){
        position = 0; //Loop
    }
    
    pos = position;

    //Is it a Media1ServerItem ?
    if(![playlist[pos] isContainer]){
        MediaServer1ItemObject *item = playlist[pos];
        
        //A few things are missing here:
        // - Find the right URI based on MIME type, do this via: [item resources], also check render capabilities 
        // = The InstanceID is set to @"0", find the right one via: "ConnetionManager PrepareForConnection"
        
        //Metadata
//        NSMutableString *metaData = [[NSMutableString alloc] init];
//        NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
//        NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
//        NSMutableString *outUpdateID = [[NSMutableString alloc] init];
        
        //Get the metadata, we need to supply it when playback
//        [[server contentDirectory] BrowseWithObjectID:[item objectID] BrowseFlag:@"BrowseMetadata" Filter:@"*" StartingIndex:@"0" RequestedCount:@"1" SortCriteria:@"+dc:title" OutResult:metaData OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
        
        
        //Find the right URI & Instance ID
//        NSMutableString *Source = [NSMutableString new];
//        NSMutableString *Sink = [NSMutableString new];
//        [[renderer connectionManager] GetProtocolInfoWithOutSource:Source OutSink:Sink];
//        NSArray *SinkArr = [Sink componentsSeparatedByString:@","];
        
//        NSMutableString *RendererOutConnectionIDs = [NSMutableString new];
//        [[renderer connectionManager] GetCurrentConnectionIDsWithOutConnectionIDs:RendererOutConnectionIDs];
//        
//        NSMutableString *OutRcsID = [NSMutableString new];
//        NSMutableString *OutAVTransportID = [NSMutableString new];
//        NSMutableString *OutProtocolInfo = [NSMutableString string];
//        NSMutableString *OutPeerConnectionManager = [NSMutableString new];
//        NSMutableString *OutPeerConnectionID = [NSMutableString new];
//        NSMutableString *OutDirection = [NSMutableString string];
//        NSMutableString *OutStatus = [NSMutableString string];
//        [[renderer connectionManager] GetCurrentConnectionInfoWithConnectionID:RendererOutConnectionIDs OutRcsID:OutRcsID OutAVTransportID:OutAVTransportID OutProtocolInfo:OutProtocolInfo OutPeerConnectionManager:OutPeerConnectionManager OutPeerConnectionID:OutPeerConnectionID OutDirection:OutDirection OutStatus:OutStatus];
        
        NSString *uri = [item uri];
        NSString *iid = @"0";//OutAVTransportID2;
        
        //Play
//        NSMutableString *OutActions = [NSMutableString string];
//        [[renderer avTransport] GetCurrentTransportActionsWithInstanceID:@"0" OutActions:OutActions];
//
//        NSMutableString *OutNrTracks = [NSMutableString string];
//        NSMutableString *OutMediaDuration = [NSMutableString string];
//        NSMutableString *OutCurrentURI = [NSMutableString string];
//        NSMutableString *OutCurrentURIMetaData = [NSMutableString string];
//        NSMutableString *OutNextURI = [NSMutableString string];
//        NSMutableString *OutNextURIMetaData = [NSMutableString string];
//        NSMutableString *OutPlayMedium = [NSMutableString string];
//        NSMutableString *OutRecordMedium = [NSMutableString string];
//        NSMutableString *OutWriteStatus = [NSMutableString string];
//        [[renderer avTransport] GetMediaInfoWithInstanceID:iid OutNrTracks:OutNrTracks OutMediaDuration:OutMediaDuration OutCurrentURI:OutCurrentURI OutCurrentURIMetaData:OutCurrentURIMetaData OutNextURI:OutNextURI OutNextURIMetaData:OutNextURIMetaData OutPlayMedium:OutPlayMedium OutRecordMedium:OutRecordMedium OutWriteStatus:OutWriteStatus];
        
        
//        [[renderer avTransport] StopWithInstanceID:iid];
//        NSString *escapedMetaData = [metaData XMLEscape];
        
//        NSDate *start = [NSDate date];
        
        MediaRenderer1Device_Swift *aRenderer = (MediaRenderer1Device_Swift *)self.atomRenderer;
        [[aRenderer avTransportService] setAVTransportURIWithInstanceID:iid currentURI:uri currentURIMetadata:@"" success:^{
            NSLog(@"Succeeded!");
            
            [[aRenderer avTransportService] playWithInstanceID:iid speed:@"1" success:^{
                NSLog(@"Succeeded!");
            } failure:^(NSError *error) {
                NSLog(@"Failed: %@", error.localizedDescription);
            }];
        } failure:^(NSError *error) {
            NSLog(@"Failed: %@", error.localizedDescription);
        }];
        
        
        
//        [[renderer avTransport] SetAVTransportURIWithInstanceID:iid CurrentURI:uri CurrentURIMetaData:@""];
//        NSLog(@"duration: %f", [start timeIntervalSinceNow]);
//        [[renderer avTransport] PlayWithInstanceID:iid Speed:@"1"];
    }
    
    return 0;
}

- (void)pause {
    [[renderer avTransport] PauseWithInstanceID:@"0"];
}

//BasicUPnPServiceObserver
-(void)UPnPEvent:(BasicUPnPService*)sender events:(NSDictionary*)events{
    NSLog(@"Event: %@", events);
    if(sender == [renderer avTransportService]){
        NSString *newState = events[@"TransportState"];
        
        if([newState isEqualToString:@"STOPPED"]){
            //Do your stuff, play next song etc...
            NSLog(@"Event: 'STOPPED', Play next track of playlist.");
//           [self Play:pos+1]; //Next
        }
    }
}

@end
