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
#import "PlayBack.h"
#import "FolderViewController.h"
#import <UPnAtom/UPnAtom-Swift.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

static const DDLogLevel ddLogLevel = DDLogLevelInfo;

@interface RootFolderViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) IBOutlet UITableView *tableView;
@end

@implementation RootFolderViewController {
    BOOL _hasSearchedForContentDirectories;
    NSArray *_devices;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Search for UPnP Devices
    [self performSSDPSearch];
    
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

#pragma mark - IBActions

- (IBAction)ssdpSearchButtonTapped:(id)sender {
    [self performSSDPSearch];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell.
    AbstractUPnPDevice *device = _devices[indexPath.row];
    [[cell textLabel] setText:[device friendlyName]];
    
    cell.accessoryType = [device isMediaServer1Device] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AbstractUPnPDevice *device = _devices[indexPath.row];
    if([device isMediaServer1Device]){
        MediaServer1Device_Swift *server = (MediaServer1Device_Swift *)device;
        if (![server contentDirectoryService]) {
            return;
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FolderViewController *targetViewController = [storyboard instantiateViewControllerWithIdentifier:@"FolderViewControllerScene"];
        [targetViewController configureWithDevice:server header:@"root" rootId:@"0"];
        
        [[self navigationController] pushViewController:targetViewController animated:YES];
        
        [[PlayBack sharedInstance] setServer:device];
    } else if([device isMediaRenderer1Device]){
        [[self toolbarLabel] setText:[device friendlyName]];
        [[PlayBack sharedInstance] setRenderer:device];
    }
}

- (void)performSSDPSearch {
    [[UPnPManager_Swift sharedInstance] searchForAll];
    [[UPnPManager_Swift sharedInstance] searchForContentDirectory];
    [[UPnPManager_Swift sharedInstance] searchForMediaRenderer];
}

#pragma mark - NSNotification callbacks

- (void)deviceWasAdded:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPDeviceKey]]) {
        AbstractUPnPDevice *upnpObject = ((AbstractUPnPDevice *)notification.userInfo[[UPnPRegistry UPnPDeviceKey]]);
        DDLogInfo(@"Added device: %@ - %@", upnpObject.className, upnpObject.friendlyName);
        DDLogVerbose(@"%@ = %@", upnpObject.className, upnpObject.description);
    }
    
    [self updateDataAndRefreshTableView];
}

- (void)deviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPDeviceKey]]) {
        AbstractUPnPDevice *upnpObject = ((AbstractUPnPDevice *)notification.userInfo[[UPnPRegistry UPnPDeviceKey]]);
        DDLogInfo(@"Removed device: %@ - %@", upnpObject.className, upnpObject.friendlyName);
        DDLogVerbose(@"%@ = %@", upnpObject.className, upnpObject.description);
    }
    
    [self updateDataAndRefreshTableView];
}

- (void)serviceWasAdded:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPServiceKey]]) {
        AbstractUPnPService *upnpObject = ((AbstractUPnPService *)notification.userInfo[[UPnPRegistry UPnPServiceKey]]);
        DDLogInfo(@"Added service: %@ - %@", upnpObject.className, upnpObject.descriptionURL);
        DDLogVerbose(@"%@ = %@", upnpObject.className, upnpObject.description);
    }
}

- (void)serviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPServiceKey]]) {
        AbstractUPnPService *upnpObject = ((AbstractUPnPService *)notification.userInfo[[UPnPRegistry UPnPServiceKey]]);
        DDLogInfo(@"Removed service: %@ - %@", upnpObject.className, upnpObject.descriptionURL);
        DDLogVerbose(@"%@ = %@", upnpObject.className, upnpObject.description);
    }
}

#pragma mark - Internal lib

- (void)updateDataAndRefreshTableView {
    UPnPRegistry *registry = [[UPnPManager_Swift sharedInstance] upnpRegistry];
    [registry rootDevices:^(NSArray *rootDevices) {
        _devices = rootDevices;
        
        [self.tableView reloadData];
    }];
}

- (UILabel *)toolbarLabel {
    UIBarButtonItem *item = (UIBarButtonItem *)self.toolbarItems.firstObject;
    return (UILabel *)item.customView;
}

@end
