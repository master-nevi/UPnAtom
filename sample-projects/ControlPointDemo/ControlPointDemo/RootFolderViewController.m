//
//  RootFolderViewController.m
//  ControlPointDemo
//
//  Created by David Robles on 11/12/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

#import "RootFolderViewController.h"
#import <upnpx/UPnPDB.h>
#import <upnpx/UPnPManager.h>
#import "PlayBack.h"
#import "FolderViewController.h"
#import "ControlPointDemo-Swift.h"

@interface RootFolderViewController () <UITableViewDataSource, UITableViewDelegate, UPnPDBObserver>
@property (nonatomic) IBOutlet UITableView *tableView;
@end

@implementation RootFolderViewController {
    BOOL _hasSearchedForContentDirectories;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UPnPDB* db = [[UPnPManager GetInstance] DB];
    UPnPDB_Swift* db2 = [[UPnPManager_Swift sharedInstance] upnpDB];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasAdded:) name:[UPnPDB_Swift UPnPDeviceWasAddedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasRemoved:) name:[UPnPDB_Swift UPnPDeviceWasRemovedNotification] object:nil];
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
    if (notification.userInfo[[UPnPDB_Swift UPnPDeviceKey]]) {
        NSLog(@"Added device: %@", ((AbstractUPnP_Swift *)notification.userInfo[[UPnPDB_Swift UPnPDeviceKey]]).description);
    }
}

- (void)deviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPDB_Swift UPnPDeviceKey]]) {
        NSLog(@"Removed device: %@", notification.userInfo[[UPnPDB_Swift UPnPDeviceKey]]);
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
