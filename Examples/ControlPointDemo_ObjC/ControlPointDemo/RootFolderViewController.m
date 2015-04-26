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

#define kUPnPObjectArchiveKey @"upnpObjectArchiveKey"

@interface RootFolderViewController () <UITableViewDataSource, UITableViewDelegate, UPnPServiceSource, UPnPDeviceSource>
@property (nonatomic) IBOutlet UITableView *tableView;
@end

@implementation RootFolderViewController {
    NSMutableArray *_discoveredDeviceUSNs;
    NSMutableDictionary *_discoveredUPnPObjectCache;
    NSMutableArray *_archivedDeviceUSNs;
    NSMutableDictionary *_archivedUPnPObjectCache;
    __weak UILabel *_toolbarLabel;
    NSOperationQueue *_archivingUnarchivingQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _discoveredDeviceUSNs = [NSMutableArray array];
    _discoveredUPnPObjectCache = [NSMutableDictionary dictionary];
    _archivedDeviceUSNs = [NSMutableArray array];
    _archivedUPnPObjectCache = [NSMutableDictionary dictionary];
    _archivingUnarchivingQueue = [NSOperationQueue new];
    _archivingUnarchivingQueue.name = @"Archiving and unarchiving queue";
    
    // initialize
    [UPnAtom sharedInstance].ssdpTypes = [[NSSet alloc] initWithArray:@[@"ssdp:all",
                                                                        @"urn:schemas-upnp-org:device:MediaServer:1",
                                                                        @"urn:schemas-upnp-org:device:MediaRenderer:1",
                                                                        @"urn:schemas-upnp-org:service:ContentDirectory:1",
                                                                        @"urn:schemas-upnp-org:service:ConnectionManager:1",
                                                                        @"urn:schemas-upnp-org:service:RenderingControl:1",
                                                                        @"urn:schemas-upnp-org:service:AVTransport:1"]];
    
    [self loadArchivedUPnPObjects];
    
    self.title = @"Control Point Demo";
    
    CGFloat viewWidth = self.navigationController.view.frame.size.width;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, viewWidth - (viewWidth * 0.2), 21.0f)];
    _toolbarLabel = titleLabel;
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor blackColor]];
    [titleLabel setText:@""];
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    NSArray *items = @[[[Player sharedInstance] playPauseButton], [[Player sharedInstance] stopButton], barButton];
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
    [self performSSDPDiscovery];
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
    return [self deviceCountForTableSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DefaultCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell.
    AbstractUPnPDevice *device = [self deviceForIndexPath:indexPath];
    [[cell textLabel] setText:[device friendlyName]];
    
    cell.accessoryType = [device isMediaServer1Device] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AbstractUPnPDevice *device = [self deviceForIndexPath:indexPath];
    if ([device isMediaServer1Device]) {
        MediaServer1Device *server = (MediaServer1Device *)device;
        if (!server.contentDirectoryService) {
            NSLog(@"%@ - has no content directory service", device.friendlyName);
            return;
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FolderViewController *targetViewController = [storyboard instantiateViewControllerWithIdentifier:@"FolderViewControllerScene"];
        [targetViewController configureWithDevice:server header:@"root" rootId:@"0"];
        
        [[self navigationController] pushViewController:targetViewController animated:YES];
        
        [[Player sharedInstance] setMediaServer:server];
    }
    else if ([device isMediaRenderer1Device]) {
        MediaRenderer1Device *aRenderer = (MediaRenderer1Device *)device;
        if (!aRenderer.avTransportService) {
            NSLog(@"%@ - has no AV transport service", device.friendlyName);
            return;
        }
        
        [_toolbarLabel setText:[device friendlyName]];
        [[Player sharedInstance] setMediaRenderer:aRenderer];
    }
}

#pragma mark - NSNotification callbacks

- (void)deviceWasAdded:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPDeviceKey]]) {
        AbstractUPnPDevice *upnpDevice = ((AbstractUPnPDevice *)notification.userInfo[[UPnPRegistry UPnPDeviceKey]]);
        NSLog(@"Added device: %@ - %@", upnpDevice.className, upnpDevice.friendlyName);
//        NSLog(@"%@ = %@", upnpDevice.className, upnpDevice.description);
        
        _discoveredUPnPObjectCache[upnpDevice.usn.rawValue] = upnpDevice;
        
        [self insertDevice:upnpDevice intoSection:1];
    }
}

- (void)deviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPDeviceKey]]) {
        AbstractUPnPDevice *upnpDevice = ((AbstractUPnPDevice *)notification.userInfo[[UPnPRegistry UPnPDeviceKey]]);
        NSLog(@"Removed device: %@ - %@", upnpDevice.className, upnpDevice.friendlyName);
//        NSLog(@"%@ = %@", upnpDevice.className, upnpDevice.description);
        
        [_discoveredUPnPObjectCache removeObjectForKey:upnpDevice.usn.rawValue];
        
        [self deleteDevice:upnpDevice fromSection:1];
    }
}

- (void)serviceWasAdded:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPServiceKey]]) {
        AbstractUPnPService *upnpService = ((AbstractUPnPService *)notification.userInfo[[UPnPRegistry UPnPServiceKey]]);
        NSLog(@"Added service: %@ - %@", upnpService.className, upnpService.device ? [NSString stringWithFormat:@"%@", upnpService.device.friendlyName] : @"Service's device object not created yet");
//        NSLog(@"%@ = %@", upnpService.className, upnpService.description);
        
        _discoveredUPnPObjectCache[upnpService.usn.rawValue] = upnpService;
    }
}

- (void)serviceWasRemoved:(NSNotification *)notification {
    if (notification.userInfo[[UPnPRegistry UPnPServiceKey]]) {
        AbstractUPnPService *upnpService = ((AbstractUPnPService *)notification.userInfo[[UPnPRegistry UPnPServiceKey]]);
        NSLog(@"Removed service: %@ - %@", upnpService.className, upnpService.device ? [NSString stringWithFormat:@"%@", upnpService.device.friendlyName] : @"Service's device object not created yet");
//        NSLog(@"%@ = %@", upnpService.className, upnpService.description);
        
        [_discoveredUPnPObjectCache removeObjectForKey:upnpService.usn.rawValue];
    }
}

#pragma mark - UPnPServiceSource methods

- (AbstractUPnPService *)serviceForUSN:(UniqueServiceName *)usn {
    return _archivedUPnPObjectCache[usn.rawValue];
}

#pragma mark - UPnPDeviceSource methods

- (AbstractUPnPDevice *)deviceForUSN:(UniqueServiceName *)usn {
    return _archivedUPnPObjectCache[usn.rawValue];
}

#pragma mark - Internal lib

- (void)performSSDPDiscovery {
    if ([[UPnAtom sharedInstance] ssdpDiscoveryRunning]) {
        [[UPnAtom sharedInstance] restartSSDPDiscovery];
    }
    else {
        [[UPnAtom sharedInstance] startSSDPDiscovery];
    }
}

- (NSUInteger)deviceCountForTableSection:(NSUInteger)section {
    return section == 0 ? _archivedDeviceUSNs.count : _discoveredDeviceUSNs.count;
}

- (AbstractUPnPDevice *)deviceForIndexPath:(NSIndexPath *)indexPath {
    NSArray *deviceUSNs = indexPath.section == 0 ? _archivedDeviceUSNs : _discoveredDeviceUSNs;
    NSString *deviceUSN = deviceUSNs[indexPath.row];
    
    NSDictionary *deviceCache = indexPath.section == 0 ? _archivedUPnPObjectCache : _discoveredUPnPObjectCache;
    return deviceCache[deviceUSN];
}

- (void)insertDevice:(AbstractUPnPDevice *)upnpDevice intoSection:(NSUInteger)section {
    NSMutableArray *deviceUSNs = section == 0 ? _archivedDeviceUSNs : _discoveredDeviceUSNs;
    
    NSUInteger index = deviceUSNs.count;
    [deviceUSNs insertObject:upnpDevice.usn.rawValue atIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:section];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)deleteDevice:(AbstractUPnPDevice *)upnpDevice fromSection:(NSUInteger)section {
    NSMutableArray *deviceUSNs = section == 0 ? _archivedDeviceUSNs : _discoveredDeviceUSNs;
    
    NSUInteger index = [deviceUSNs indexOfObject:upnpDevice.usn.rawValue];
    [deviceUSNs removeObjectAtIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:section];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)archiveUPnPObjects {
    [_archivingUnarchivingQueue addOperationWithBlock:^{
        // archive discovered objects
        NSMutableArray *upnpArchivables = [NSMutableArray array];
        
        [_discoveredUPnPObjectCache enumerateKeysAndObjectsUsingBlock:^(NSString *usn, AbstractUPnP *upnpObject, BOOL *stop) {
            NSString *friendlyName = @"Unknown";
            if ([upnpObject isAbstractUPnPDevice]) {
                friendlyName = ((AbstractUPnPDevice *)upnpObject).friendlyName;
            }
            else if ([upnpObject isAbstractUPnPService]) {
                friendlyName = ((AbstractUPnPService *)upnpObject).device.friendlyName;
            }
            
            UPnPArchivableAnnex *upnpArchivable = [upnpObject archivableWithCustomMetadata:@{@"upnpType": upnpObject.className, @"friendlyName": friendlyName}];
            [upnpArchivables addObject:upnpArchivable];
        }];
        
        NSData *upnpArchivablesData = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:upnpArchivables]];
        [[NSUserDefaults standardUserDefaults] setObject:upnpArchivablesData forKey:kUPnPObjectArchiveKey];
        
        // show archive complete alert
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Archive Complete!" message:@"Load archive and reload table view? If cancelled you'll see the archived devices on the next launch." preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self loadArchivedUPnPObjects];
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        }];
    }];
}

- (void)loadArchivedUPnPObjects {
    // clear previously loaded archive devices
    if (_archivedDeviceUSNs.count) {
        NSMutableArray *currentArchivedDeviceIndexes = [NSMutableArray array];
        for (NSUInteger i = 0; i < _archivedDeviceUSNs.count; i++) {
            [currentArchivedDeviceIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [_archivedDeviceUSNs removeAllObjects];
        [self.tableView deleteRowsAtIndexPaths:currentArchivedDeviceIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    // clear archive model
    [_archivedUPnPObjectCache removeAllObjects];
    
    [_archivingUnarchivingQueue addOperationWithBlock:^{
        // load archived objects
        NSData *upnpArchivablesData = [[NSUserDefaults standardUserDefaults] objectForKey:kUPnPObjectArchiveKey];
        if (upnpArchivablesData != nil) {
            NSArray *upnpArchivables = [NSKeyedUnarchiver unarchiveObjectWithData:upnpArchivablesData];
            
            for (UPnPArchivableAnnex *upnpArchivable in upnpArchivables) {
                NSLog(@"Unarchived upnp object from cache %@ - %@", upnpArchivable.customMetadata[@"upnpType"], upnpArchivable.customMetadata[@"friendlyName"]);
                [[[UPnAtom sharedInstance] upnpRegistry] createUPnPObjectWithUpnpArchivable:upnpArchivable callbackQueue:[NSOperationQueue mainQueue] success:^(AbstractUPnP *upnpObject) {
                    NSLog(@"Re-created upnp object %@ - %@", upnpObject.className, upnpArchivable.customMetadata[@"friendlyName"]);
                    
                    _archivedUPnPObjectCache[upnpObject.usn.rawValue] = upnpObject;
                    
                    if ([upnpObject isAbstractUPnPDevice]) {
                        AbstractUPnPDevice *upnpDevice = (AbstractUPnPDevice *)upnpObject;
                        upnpDevice.serviceSource = self;
                        
                        [self insertDevice:upnpDevice intoSection:0];
                    }
                    else if ([upnpObject isAbstractUPnPService]) {
                        AbstractUPnPService *upnpService = (AbstractUPnPService *)upnpObject;
                        upnpService.deviceSource = self;
                    }
                } failure:^(NSError *error) {
                    NSLog(@"Failed to create UPnP Object from archive");
                }];
            }
        }
        else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self performSSDPDiscovery];
            }];
        }
    }];
}

@end
