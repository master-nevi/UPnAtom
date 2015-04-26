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
#import "Player.h"
@import UPnAtom;

@interface FolderViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) IBOutlet UITableView *tableView;
@end

@implementation FolderViewController {
    NSString *_rootId;
    MediaServer1Device *_device;
    NSArray *_playlist;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_device.contentDirectoryService getSortCapabilities:^(NSString *sortCaps) {
        if ([sortCaps rangeOfString:@"dc:title"].location != NSNotFound) {
            sortCaps = @"+dc:title";
        }
        
        [_device.contentDirectoryService browseWithObjectID:_rootId browseFlag:@"BrowseDirectChildren" filter:@"*" startingIndex:@"0" requestedCount:@"0" sortCriteria:sortCaps success:^(NSArray *result, NSInteger numberReturned, NSInteger totalMatches, NSString *updateID) {
            _playlist = result;
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            NSLog(@"failed to browse content directory");
        }];
    } failure:^(NSError *error) {
        NSLog(@"failed to get sort capabilities");
    }];
    
    CGFloat viewWidth = self.navigationController.view.frame.size.width;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 11.0f, viewWidth - (viewWidth * 0.2), 21.0f)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor blackColor]];
    
    if([[Player sharedInstance] mediaRenderer] == nil){
        [titleLabel setText:@"No Renderer Selected"];
    }else{
        [titleLabel setText:[[[Player sharedInstance] mediaRenderer] friendlyName] ];
    }
    
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    NSArray *items = @[[[Player sharedInstance] playPauseButton], [[Player sharedInstance] stopButton], title];
    self.toolbarItems = items;
    
    self.navigationController.toolbarHidden = NO;
}

- (void)configureWithDevice:(MediaServer1Device *)device header:(NSString *)header rootId:(NSString *)rootId{
    _device = device;
    _rootId = rootId;
    self.title = header;
    _playlist = [NSArray array];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_playlist count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DefaultCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell...
    ContentDirectory1Object *item = _playlist[indexPath.row];
    [[cell textLabel] setText:[item title]];
    
    cell.accessoryType = item.isContentDirectory1Container ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ContentDirectory1Object *item = _playlist[indexPath.row];
    if([item isContentDirectory1Container]){
        ContentDirectory1Container *container = _playlist[indexPath.row];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FolderViewController *targetViewController = [storyboard instantiateViewControllerWithIdentifier:@"FolderViewControllerScene"];
        [targetViewController configureWithDevice:_device header:[container title] rootId:[container objectID]];
        
        [[self navigationController] pushViewController:targetViewController animated:YES];
    }else{
        [[Player sharedInstance] startPlayback:_playlist position:indexPath.row];
    }
}

@end
