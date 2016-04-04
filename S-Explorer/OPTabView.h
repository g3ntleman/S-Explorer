//
//  OPTabView.h
//  OPTabView
//
//  Created by Dirk Theisen on 27.09.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OPTabView : NSTabView

@property (strong, nonatomic) NSColor* backgroundColor;
@property (readonly) NSSegmentedControl* tabButtons;
@property BOOL drawsBorder; // if set to NO, draws only a line

@end

@interface NSTabView (OPTabView)

- (NSUInteger) indexOfSelectedTabViewItem;

@end