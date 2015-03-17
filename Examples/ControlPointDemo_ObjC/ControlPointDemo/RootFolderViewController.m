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
#import "Player.h"
#import "FolderViewController.h"
@import UPnAtom;

#define kUPnPArchiveKey @"upnpArchiveKey"

@interface RootFolderViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) IBOutlet UITableView *tableView;
@end

@implementation RootFolderViewController {
    NSMutableArray *_discoveredDevices;
    NSMutableArray *_archivedDevices;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _discoveredDevices = [NSMutableArray array];
    _archivedDevices = [NSMutableArray array];
    
    [self loadArchivedObjects];
    
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
    
    if (![[UPnAtom sharedInstance] ssdpDiscoveryRunning]) {
        //Search for UPnP Devices
        [[UPnAtom sharedInstance] startSSDPDiscovery];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[UPnPRegistry UPnPDeviceAddedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[UPnPRegistry UPnPDeviceRemovedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[UPnPRegistry UPnPServiceAddedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[UPnPRegistry UPnPServiceRemovedNotification] object:nil];
    
    [super viewDidDisappear:animated];
}

#pragma mark - IBActions

- (IBAction)ssdpSearchButtonTapped:(id)sender {
    [[UPnAtom sharedInstance] restartSSDPDiscovery];
}

- (IBAction)archiveButtonTapped:(id)sender {
    NSMutableArray *archivableUPnPs = [NSMutableArray array];
    
    for (AbstractUPnPDevice *device in _discoveredDevices) {
        UPnPArchivableAnnex *archivable = [device archivableWithCustomMetadata:@{@"friendlyName": device.friendlyName}];
        [archivableUPnPs addObject:archivable];
    }
    
    NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:archivableUPnPs]];
    
    [[NSUserDefaults standardUserDefaults] setObject:archiveData forKey:kUPnPArchiveKey];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Archive Complete" message:@"Reload table view? If cancelled you'll see it on the next launch" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self loadArchivedObjects];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Archived Devices" : @"Discovered Devices";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *devices = section == 0 ? _archivedDevices : _discoveredDevices;
    return devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DefaultCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell.
    NSArray *devices = indexPath.section == 0 ? _archivedDevices : _discoveredDevices;
    AbstractUPnPDevice *device = devices[indexPath.row];
    [[cell textLabel] setText:[device friendlyName]];
    
    cell.accessoryType = [device isMediaServer1Device] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *devices = indexPath.section == 0 ? _archivedDevices : _discoveredDevices;
    AbstractUPnPDevice *device = devices[indexPath.row];
    if ([device isMediaServer1Device]) {
        MediaServer1Device *server = (MediaServer1Device *)device;
        if (![server contentDirectoryService]) {
            NSLog(@"%@ - has no content directory service", device.friendlyName);
            return;
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FolderViewController *targetViewController = [storyboard instantiateViewControllerWithIdentifier:@"FolderViewControllerScene"];
        [targetViewController configureWithDevice:server header:@"root" rootId:@"0"];
        
        [[self navigationController] pushViewController:targetViewController animated:YES];
        
        [[Player sharedInstance] setServer:device];
    }
    else if ([device isMediaRenderer1Device]) {
        MediaRenderer1Device *aRenderer = (MediaRenderer1Device *)device;
        if (![aRenderer avTransportService]) {
            NSLog(@"%@ - has no AV transport service", device.friendlyName);
            return;
        }
        
        [[self toolbarLabel] setText:[device friendlyName]];
        [[Player sharedInstance] setRenderer:device];
    }
}

#pragma mark - NSNotification callbacks

- (void)deviceWasAdded:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPDeviceKey]]) {
        AbstractUPnPDevice *upnpDevice = ((AbstractUPnPDevice *)notification.userInfo[[UPnPRegistry UPnPDeviceKey]]);
        NSLog(@"Added device: %@ - %@", upnpDevice.className, upnpDevice.friendlyName);
//        NSLog(@"%@ = %@", upnpDevice.className, upnpDevice.description);
        
        NSUInteger index = _discoveredDevices.count;
        [_discoveredDevices insertObject:upnpDevice atIndex:index];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)deviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPDeviceKey]]) {
        AbstractUPnPDevice *upnpDevice = ((AbstractUPnPDevice *)notification.userInfo[[UPnPRegistry UPnPDeviceKey]]);
        NSLog(@"Removed device: %@ - %@", upnpDevice.className, upnpDevice.friendlyName);
//        NSLog(@"%@ = %@", upnpDevice.className, upnpDevice.description);
        
        NSUInteger index = [_discoveredDevices indexOfObject:upnpDevice];
        [_discoveredDevices removeObjectAtIndex:index];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)serviceWasAdded:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPServiceKey]]) {
        AbstractUPnPService *upnpService = ((AbstractUPnPService *)notification.userInfo[[UPnPRegistry UPnPServiceKey]]);
        NSLog(@"Added service: %@ - %@", upnpService.className, upnpService.descriptionURL);
//        NSLog(@"%@ = %@", upnpService.className, upnpService.description);
    }
}

- (void)serviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPServiceKey]]) {
        AbstractUPnPService *upnpService = ((AbstractUPnPService *)notification.userInfo[[UPnPRegistry UPnPServiceKey]]);
        NSLog(@"Removed service: %@ - %@", upnpService.className, upnpService.descriptionURL);
//        NSLog(@"%@ = %@", upnpService.className, upnpService.description);
    }
}

#pragma mark - Internal lib

- (UILabel *)toolbarLabel {
    UIBarButtonItem *item = (UIBarButtonItem *)self.toolbarItems.firstObject;
    return (UILabel *)item.customView;
}

- (void)loadArchivedObjects {
    if (_archivedDevices.count) {
        NSMutableArray *currentArchivedDeviceIndexes = [NSMutableArray array];
        for (NSUInteger i = 0; i < _archivedDevices.count; i++) {
            [currentArchivedDeviceIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [_archivedDevices removeAllObjects];
        [self.tableView deleteRowsAtIndexPaths:currentArchivedDeviceIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    NSData *archivedUPnPData = [[NSUserDefaults standardUserDefaults] objectForKey:kUPnPArchiveKey];
    if (archivedUPnPData != nil) {
        NSArray *unarchivedUPnPs = [NSKeyedUnarchiver unarchiveObjectWithData:archivedUPnPData];
        
        for (UPnPArchivableAnnex *archivable in unarchivedUPnPs) {
            NSLog(@"Unarchived %@", archivable.customMetadata[@"friendlyName"]);
            [[[UPnAtom sharedInstance] upnpRegistry] createUPnPObject:archivable success:^(AbstractUPnP *upnpObject) {
//                NSLog(@"Re-created %@: %@ = %@", archivable.customMetadata[@"friendlyName"], upnpObject.className, upnpObject.description);
                
                NSUInteger index = _archivedDevices.count;
                [_archivedDevices insertObject:upnpObject atIndex:index];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } failure:^(NSError *error) {
                NSLog(@"Failed to create UPnP Object from archive");
            }];
        }
    }
}

@end
