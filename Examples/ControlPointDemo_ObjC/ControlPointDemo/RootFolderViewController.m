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

#define kUPnPDeviceArchiveKey @"upnpDeviceArchiveKey"
#define kUPnPServiceArchiveKey @"upnpServiceArchiveKey"

@interface RootFolderViewController () <UITableViewDataSource, UITableViewDelegate, UPnPServiceSource>
@property (nonatomic) IBOutlet UITableView *tableView;
@end

@implementation RootFolderViewController {
    NSMutableArray *_discoveredDevices;
    NSMutableArray *_archivedDevices;
    NSMutableDictionary *_archivedServices;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _discoveredDevices = [NSMutableArray array];
    _archivedDevices = [NSMutableArray array];
    _archivedServices = [NSMutableDictionary dictionary];
    
    // initialize
    [UPnAtom sharedInstance];
    
    [self loadArchivedUPnPObjects];
    
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[UPnPRegistry UPnPDeviceAddedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[UPnPRegistry UPnPDeviceRemovedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[UPnPRegistry UPnPServiceAddedNotification] object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[UPnPRegistry UPnPServiceRemovedNotification] object:nil];
    
    [super viewDidDisappear:animated];
}

#pragma mark - IBActions

- (IBAction)discoverButtonTapped:(id)sender {
    //Search for UPnP devices and services
    if ([[UPnAtom sharedInstance] ssdpDiscoveryRunning]) {
        [[UPnAtom sharedInstance] restartSSDPDiscovery];
    }
    else {   
        [[UPnAtom sharedInstance] startSSDPDiscovery];
    }
}

- (IBAction)archiveButtonTapped:(id)sender {
    [self archiveUPnPObjects];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Archived Devices" : @"Discovered Devices";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *devices = [self devicesForTableSection:section];
    return devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DefaultCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell.
    NSArray *devices = [self devicesForTableSection:indexPath.section];
    AbstractUPnPDevice *device = devices[indexPath.row];
    [[cell textLabel] setText:[device friendlyName]];
    
    cell.accessoryType = [device isMediaServer1Device] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *devices = [self devicesForTableSection:indexPath.section];
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
        NSLog(@"Added service: %@", upnpService.className);
//        NSLog(@"%@ = %@", upnpService.className, upnpService.description);
    }
}

- (void)serviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPServiceKey]]) {
        AbstractUPnPService *upnpService = ((AbstractUPnPService *)notification.userInfo[[UPnPRegistry UPnPServiceKey]]);
        NSLog(@"Removed service: %@", upnpService.className);
//        NSLog(@"%@ = %@", upnpService.className, upnpService.description);
    }
}

#pragma mark - UPnPServiceSource methods

- (AbstractUPnPService *)serviceForUsn:(UniqueServiceName *)usn {
    return _archivedServices[usn.rawValue];
}

#pragma mark - Internal lib

- (UILabel *)toolbarLabel {
    UIBarButtonItem *item = (UIBarButtonItem *)self.toolbarItems.firstObject;
    return (UILabel *)item.customView;
}

- (NSArray *)devicesForTableSection:(NSUInteger)section {
    return section == 0 ? _archivedDevices : _discoveredDevices;
}

- (void)archiveUPnPObjects {
    // archive devices
    [[[UPnAtom sharedInstance] upnpRegistry] upnpDevices:^(NSArray *upnpDevices) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *deviceArchivables = [NSMutableArray array];
            
            for (AbstractUPnPDevice *device in upnpDevices) {
                UPnPArchivableAnnex *deviceArchivable = [device archivableWithCustomMetadata:@{@"upnpType": device.className, @"friendlyName": device.friendlyName}];
                [deviceArchivables addObject:deviceArchivable];
            }
            
            NSData *deviceArchivablesData = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:deviceArchivables]];
            [[NSUserDefaults standardUserDefaults] setObject:deviceArchivablesData forKey:kUPnPDeviceArchiveKey];
            
            // archive services
            [[[UPnAtom sharedInstance] upnpRegistry] upnpServices:^(NSArray *upnpServices) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSMutableArray *serviceArchivables = [NSMutableArray array];
                    
                    for (AbstractUPnPService *service in upnpServices) {
                        UPnPArchivableAnnex *serviceArchivable = [service archivableWithCustomMetadata:@{@"upnpType": service.className}];
                        [serviceArchivables addObject:serviceArchivable];
                    }
                    
                    NSData *serviceArchivablesData = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:serviceArchivables]];
                    [[NSUserDefaults standardUserDefaults] setObject:serviceArchivablesData forKey:kUPnPServiceArchiveKey];
                    
                    // show archive complete alert
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Archive Complete!" message:@"Load archive and reload table view? If cancelled you'll see the archived devices on the next launch." preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            [self loadArchivedUPnPObjects];
                        }]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    });
                });
            }];
        });
    }];
}

- (void)loadArchivedUPnPObjects {
    // clear previously loaded devices
    if (_archivedDevices.count) {
        NSMutableArray *currentArchivedDeviceIndexes = [NSMutableArray array];
        for (NSUInteger i = 0; i < _archivedDevices.count; i++) {
            [currentArchivedDeviceIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [_archivedDevices removeAllObjects];
        [self.tableView deleteRowsAtIndexPaths:currentArchivedDeviceIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    // clear previously loaded services
    if (_archivedServices.count) {
        [_archivedServices removeAllObjects];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // load archived devices
        NSData *deviceArchivablesData = [[NSUserDefaults standardUserDefaults] objectForKey:kUPnPDeviceArchiveKey];
        if (deviceArchivablesData != nil) {
            NSArray *deviceArchivables = [NSKeyedUnarchiver unarchiveObjectWithData:deviceArchivablesData];
            
            for (UPnPArchivableAnnex *deviceArchivable in deviceArchivables) {
                NSLog(@"Unarchived device from cache %@ - %@", deviceArchivable.customMetadata[@"upnpType"], deviceArchivable.customMetadata[@"friendlyName"]);
                [[[UPnAtom sharedInstance] upnpRegistry] createUPnPObject:deviceArchivable success:^(AbstractUPnP *upnpObject) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"Re-created device %@ - %@", upnpObject.className, deviceArchivable.customMetadata[@"friendlyName"]);
                        
                        AbstractUPnPDevice *upnpDevice = (AbstractUPnPDevice *)upnpObject;
                        
                        upnpDevice.serviceSource = self;
                        
                        NSUInteger index = _archivedDevices.count;
                        [_archivedDevices insertObject:upnpDevice atIndex:index];
                        
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    });
                } failure:^(NSError *error) {
                    NSLog(@"Failed to create UPnP Object from archive");
                }];
            }
        }
        
        // load archived services
        NSData *serviceArchivablesData = [[NSUserDefaults standardUserDefaults] objectForKey:kUPnPServiceArchiveKey];
        if (serviceArchivablesData != nil) {
            NSArray *serviceArchivables = [NSKeyedUnarchiver unarchiveObjectWithData:serviceArchivablesData];
            
            for (UPnPArchivableAnnex *serviceArchivable in serviceArchivables) {
                NSLog(@"Unarchived service from cache %@", serviceArchivable.customMetadata[@"upnpType"]);
                [[[UPnAtom sharedInstance] upnpRegistry] createUPnPObject:serviceArchivable success:^(AbstractUPnP *upnpObject) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"Re-created service %@", upnpObject.className);
                        _archivedServices[upnpObject.usn.rawValue] = upnpObject;
                    });
                } failure:^(NSError *error) {
                    NSLog(@"Failed to create UPnP Object from archive");
                }];
            }
        }
    });
}

@end
