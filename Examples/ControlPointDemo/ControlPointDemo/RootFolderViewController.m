//
//  RootFolderViewController.m
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

#import "RootFolderViewController.h"
#import <upnpx/UPnPDB.h>
#import <upnpx/UPnPManager.h>
#import "PlayBack.h"
#import "FolderViewController.h"
#import <UPnAtom/UPnAtom-Swift.h>

@interface RootFolderViewController () <UITableViewDataSource, UITableViewDelegate, UPnPDBObserver>
@property (nonatomic) IBOutlet UITableView *tableView;
@end

@implementation RootFolderViewController {
    BOOL _hasSearchedForContentDirectories;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UPnPDB* db = [[UPnPManager GetInstance] DB];
    UPnPRegistry* db2 = [[UPnPManager_Swift sharedInstance] upnpRegistry];
    NSLog(@"%@", db2);
    [db addObserver:self];
    
    //Search for UPnP Devices
    [[[UPnPManager GetInstance] SSDP] searchSSDP];
    
    self.title = @"Control Point Demo";
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, self.navigationController.view.frame.size.width, 21.0f)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor blackColor]];
    [titleLabel setText:@""];
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    NSArray *items = @[barButton];
    self.toolbarItems = items;
    
    self.navigationController.toolbarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasAdded:) name:[UPnPRegistry UPnPDeviceAddedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasRemoved:) name:[UPnPRegistry UPnPDeviceRemovedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceWasAdded:) name:[UPnPRegistry UPnPServiceAddedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceWasRemoved:) name:[UPnPRegistry UPnPServiceRemovedNotification] object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)dealloc {
    
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self devices] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell.
    BasicUPnPDevice *device = [self devices][indexPath.row];
    [[cell textLabel] setText:[device friendlyName]];
    
    BOOL isMediaServer = [device.urn isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"];
    cell.accessoryType = isMediaServer ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BasicUPnPDevice *device = [self devices][indexPath.row];
    if([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaServer:1"]){
        MediaServer1Device *server = (MediaServer1Device*)device;
        if (![server contentDirectory]) {
            return;
        }
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FolderViewController *targetViewController = [storyboard instantiateViewControllerWithIdentifier:@"FolderViewControllerScene"];
        [targetViewController configureWithDevice:server header:@"root" rootId:@"0"];
        
        [[self navigationController] pushViewController:targetViewController animated:YES];
        [[PlayBack GetInstance] setServer:server];
    } else if([[device urn] isEqualToString:@"urn:schemas-upnp-org:device:MediaRenderer:1"]){
        [[self toolbarLabel] setText:[device friendlyName]];
        MediaRenderer1Device *render = (MediaRenderer1Device*)device;
        [[PlayBack GetInstance] setRenderer:render];
    }
}

#pragma mark - UPnPDBObserver methods

-(void)UPnPDBWillUpdate:(UPnPDB*)sender{
    //    NSLog(@"UPnPDBWillUpdate %lu", (unsigned long)[mDevices count]);
}

-(void)UPnPDBUpdated:(UPnPDB*)sender{
    //    NSLog(@"UPnPDBUpdated %lu", (unsigned long)[mDevices count]);
    if (!_hasSearchedForContentDirectories) {
        _hasSearchedForContentDirectories = YES;
        [self performSSDPSearch];
    }
    
//    for (BasicUPnPDevice *device in [self devices]) {
//        NSLog(@"Device: %@", device.description);
//    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)performSSDPSearch {
    [[[UPnPManager GetInstance] SSDP] searchForContentDirectory];
    [[[UPnPManager GetInstance] SSDP] searchForMediaRenderer];
}

#pragma mark - NSNotification callbacks

- (void)deviceWasAdded:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPDeviceKey]]) {
//        AbstractUPnP *upnpObject = ((AbstractUPnP *)notification.userInfo[[UPnPRegistry UPnPDeviceKey]]);
//        NSLog(@"Added device: %@ %@", upnpObject.className, upnpObject.description);
    }
}

- (void)deviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPDeviceKey]]) {
        AbstractUPnP *upnpObject = ((AbstractUPnP *)notification.userInfo[[UPnPRegistry UPnPDeviceKey]]);
        NSLog(@"Removed device: %@ %@", upnpObject.className, upnpObject.description);
    }
}

- (void)serviceWasAdded:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPServiceKey]]) {
        AbstractUPnP *upnpObject = ((AbstractUPnP *)notification.userInfo[[UPnPRegistry UPnPServiceKey]]);
        NSLog(@"Added service: %@ %@", upnpObject.className, upnpObject.description);
        if (![upnpObject.baseURL.absoluteString containsString:@":5001"]) {
            return;
        }
        
        if ([upnpObject.className isEqualToString:@"ContentDirectory1Service"]) {
            ContentDirectory1Service *contentDirectoryService = (ContentDirectory1Service *)upnpObject;
            [contentDirectoryService getSortCapabilities:^(NSString *sortCapabilities) {
                NSLog(@"sort capabilities: %@", sortCapabilities);
            } failure:^(NSError *error) {
                
            }];
            
            [contentDirectoryService browse:@"0" browseFlag:@"BrowseDirectChildren" filter:@"*" startingIndex:@"0" requestedCount:@"0" sortCriteria:@"" success:^(NSString *result, NSString *numberReturned, NSString *totalMatches, NSString *updateID) {
                NSLog(@"browse: %@\nnumberReturned: %@\ntotalMatches: %@\nupdateID: %@", result, numberReturned, totalMatches, updateID);
            } failure:^(NSError *error) {
                
            }];
        }
    }
}

- (void)serviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPServiceKey]]) {
        AbstractUPnP *upnpObject = ((AbstractUPnP *)notification.userInfo[[UPnPRegistry UPnPServiceKey]]);
        NSLog(@"Removed service: %@ %@", upnpObject.className, upnpObject.description);
    }
}

#pragma mark - Internal lib

- (NSArray *)devices {
    UPnPDB* db = [[UPnPManager GetInstance] DB];
    return [db rootDevices];
}

- (UILabel *)toolbarLabel {
    UIBarButtonItem *item = (UIBarButtonItem *)self.toolbarItems.firstObject;
    return (UILabel *)item.customView;
}

@end
