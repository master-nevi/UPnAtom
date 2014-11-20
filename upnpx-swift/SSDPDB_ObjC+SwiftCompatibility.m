//
//  SSDPDB_ObjC+SwiftCompatibility.m
//  ControlPointDemo
//
//  Created by David Robles on 11/17/14.
//  Copyright (c) 2014 David Robles. All rights reserved.
//

#import "SSDPDB_ObjC+SwiftCompatibility.h"

@implementation SSDPDB_ObjC (SwiftCompatibility)

- (NSUInteger)addSSDPDBObserver:(id <SSDPDB_ObjC_Observer>)obs {
    return [self addObserver:(SSDPDB_ObjC_Observer *)obs];
}

@end
