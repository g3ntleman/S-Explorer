//
//  NSView+OPCopying.m
//  S-Explorer
//
//  Created by Dirk Theisen on 28.09.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "NSView+OPCopying.h"

@implementation NSView (OPCopying) 

- (id) mutableCopyWithZone: (NSZone*) zone {
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject: self];
    id copy = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    return copy;
}

@end
