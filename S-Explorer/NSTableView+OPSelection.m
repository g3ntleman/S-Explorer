//
//  NSTableView+OPSelection.m
//  S-Explorer
//
//  Created by Dirk Theisen on 30.07.14.
//  Copyright (c) 2014 Cocoanuts. All rights reserved.
//

#import "NSTableView+OPSelection.h"

@implementation NSTableView (OPSelection)

/**
 * Convenience for NSTableViews with single selection.
 */
- (void) selectRowIndex: (NSUInteger) rowIndex {
    [self selectRowIndexes: [NSIndexSet indexSetWithIndex: rowIndex] byExtendingSelection: NO];
}

@end
