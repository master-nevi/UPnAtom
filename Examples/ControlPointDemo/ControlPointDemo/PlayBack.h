//
//  PlayBack.h
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

#import <Foundation/Foundation.h>
#import <upnpx/Pods-upnpx-umbrella.h>
#import <UPnAtom/UPnAtom-Swift.h>

@interface PlayBack : NSObject <BasicUPnPServiceObserver> {
    MediaRenderer1Device *__weak renderer;
    MediaServer1Device *server;
    NSMutableArray *playlist; //MediaServer1BasicObject (can be: MediaServer1ContainerObject, MediaServer1ItemObject)
    NSInteger pos;
}

+(PlayBack*)GetInstance;

-(void)setRenderer:(MediaRenderer1Device*)rend;
-(int)Play:(NSMutableArray*)playList position:(NSInteger)position;
-(int)Play:(NSInteger)position;
- (void)pause;

//BasicUPnPServiceObserver
-(void)UPnPEvent:(BasicUPnPService*)sender events:(NSDictionary*)events;

@property (strong) MediaServer1Device *server;
@property (weak, readonly) MediaRenderer1Device *renderer;
@property (strong) NSMutableArray *playlist;

@property (nonatomic) AbstractUPnPDevice *atomServer;
@property (nonatomic) AbstractUPnPDevice *atomRenderer;

@end

