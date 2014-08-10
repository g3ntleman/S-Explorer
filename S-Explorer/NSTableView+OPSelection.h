//
//  NSTableView+OPSelection.h
//  S-Explorer
//
//  Created by Dirk Theisen on 30.07.14.
//  Copyright (c) 2014 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSTableView (OPSelection)

/**
 * Convenience for NSTableViews with single selection.
 */
- (void) selectRowIndex: (NSUInteger) rowIndex;

@end
