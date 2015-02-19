//
//  FolderViewController.m
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

#import "FolderViewController.h"
#import <upnpx/MediaServer1Device.h>
#import <upnpx/MediaServer1BasicObject.h>
#import <upnpx/MediaServer1ContainerObject.h>
#import <upnpx/MediaServer1ItemObject.h>
#import <upnpx/MediaServer1ItemRes.h>
#import "PlayBack.h"
#import <upnpx/MediaServerBasicObjectParser.h>

@interface FolderViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) IBOutlet UITableView *tableView;
@end

@implementation FolderViewController {
    NSString *_rootId;
    MediaServer1Device *_device;
    NSMutableArray *_playlist;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Before we do anything, some devices do not support sorting and will fail if we try to sort on our request
    NSString *sortCriteria = @"";
    NSMutableString *outSortCaps = [[NSMutableString alloc] init];
    [[_device contentDirectory] GetSortCapabilitiesWithOutSortCaps:outSortCaps];
    
    if ([outSortCaps rangeOfString:@"dc:title"].location != NSNotFound) {
        sortCriteria = @"+dc:title";
    }
    
    //Allocate NMSutableString's to read the results
    NSMutableString *outResult = [[NSMutableString alloc] init];
    NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
    NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
    NSMutableString *outUpdateID = [[NSMutableString alloc] init];
    
    [[_device contentDirectory] BrowseWithObjectID:_rootId BrowseFlag:@"BrowseDirectChildren" Filter:@"*" StartingIndex:@"0" RequestedCount:@"0" SortCriteria:sortCriteria OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];
    //    SoapActionsAVTransport1* _avTransport = [m_device avTransport];
    //    SoapActionsConnectionManager1* _connectionManager = [m_device connectionManager];
    
    //The collections are returned as DIDL Xml in the string 'outResult'
    //upnpx provide a helper class to parse the DIDL Xml in usable MediaServer1BasicObject object
    //(MediaServer1ContainerObject and MediaServer1ItemObject)
    //Parse the return DIDL and store all entries as objects in the 'mediaObjects' array
    [_playlist removeAllObjects];
    NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
    MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:_playlist itemsOnly:NO];
    [parser parseFromData:didl];
    [self.tableView reloadData];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, self.navigationController.view.frame.size.width, 21.0f)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor blackColor]];
    
    if([[PlayBack GetInstance] renderer] == nil){
        [titleLabel setText:@"No Renderer Selected"];
    }else{
        [titleLabel setText:[[[PlayBack GetInstance] renderer] friendlyName] ];
    }
    
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    NSArray *items = @[title];
    self.toolbarItems = items;
    
    self.navigationController.toolbarHidden = NO;
}

- (void)configureWithDevice:(MediaServer1Device *)device header:(NSString*)header rootId:(NSString*)rootId{
    _device = device;
    _rootId = rootId;
    self.title = header;
    _playlist = [[NSMutableArray alloc] init];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_playlist count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    MediaServer1BasicObject *item = _playlist[indexPath.row];
    [[cell textLabel] setText:[item title]];
    
    cell.accessoryType = item.isContainer ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MediaServer1BasicObject *item = _playlist[indexPath.row];
    if([item isContainer]){
        MediaServer1ContainerObject *container = _playlist[indexPath.row];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FolderViewController *targetViewController = [storyboard instantiateViewControllerWithIdentifier:@"FolderViewControllerScene"];
        [targetViewController configureWithDevice:_device header:[container title] rootId:[container objectID]];
        
        [[self navigationController] pushViewController:targetViewController animated:YES];
    }else{
        MediaServer1ItemObject *item = _playlist[indexPath.row];
        
        MediaServer1ItemRes *resource = nil;
        NSEnumerator *e = [[item resources] objectEnumerator];
        while((resource = (MediaServer1ItemRes*)[e nextObject])){
            NSLog(@"%@ - %d, %@, %d, %lld, %d, %@", [item title], [resource bitrate], [resource duration], [resource nrAudioChannels], [resource size],  [resource durationInSeconds],  [resource protocolInfo] );
        }
        
        [[PlayBack GetInstance] Play:_playlist position:indexPath.row];
    }
}

@end
