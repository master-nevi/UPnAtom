//
//  FolderViewController.h
//  ControlPointDemo
//
//  Created by David Robles on 11/12/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MediaServer1Device;

@interface FolderViewController : UIViewController

- (void)configureWithDevice:(MediaServer1Device *)device header:(NSString*)header rootId:(NSString*)rootId;

@end
