//
//  SSDPDB_ObjC+SwiftCompatibility.h
//  ControlPointDemo
//
//  Created by David Robles on 11/17/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

#import "SSDPDB_ObjC.h"

@interface SSDPDB_ObjC (SwiftCompatibility)

- (NSUInteger)addSSDPDBObserver:(id <SSDPDB_ObjC_Observer>)obs;

@end
