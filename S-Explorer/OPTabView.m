//
//  OPTabView.m
//  OPTabView
//
//  Created by Dirk Theisen on 27.09.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "OPTabView.h"

@implementation OPTabView {
    NSTabViewType tabViewType;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _tabButtons = [[NSSegmentedControl alloc] initWithFrame: NSZeroRect];
        [self syncTabButtons];
        [self addSubview: _tabButtons];
    }
    return self;
}

- (void) syncTabButtons {
    _tabButtons.segmentCount = self.tabViewItems.count;
    [self.tabViewItems enumerateObjectsUsingBlock:^(NSTabViewItem* item, NSUInteger index, BOOL *stop) {
        [_tabButtons setLabel: item.label forSegment: index];
    }];
    _tabButtons.selectedSegment = [self.tabViewItems indexOfObject: self.selectedTabViewItem];
    _tabButtons.action = @selector(didSelectSegment:);
    _tabButtons.target = self;
    [_tabButtons sizeToFit];
}

- (void) setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    CGRect tabButtonsFrame = _tabButtons.frame;
    tabButtonsFrame.origin.y = 7.0;
    tabButtonsFrame.origin.x = (frameRect.size.width - tabButtonsFrame.size.width) / 2.0;
    _tabButtons.frame = tabButtonsFrame;
    
    //[self.selectedTabViewItem.view setFrame: self.contentRect];
}

- (void) awakeFromNib {
    self.backgroundColor = [NSColor whiteColor];
    self.drawsBackground = NO; // does nothing
    self.tabViewType = NSTopTabsBezelBorder;
    _tabButtons = [[NSSegmentedControl alloc] initWithFrame: NSZeroRect];
    [self syncTabButtons];
    [self addSubview: _tabButtons];
}

- (IBAction) didSelectSegment: (id) sender {
    [self selectTabViewItemAtIndex: [sender selectedSegment]];
}

- (void) addTabViewItem:(NSTabViewItem *)tabViewItem {
    [super addTabViewItem: tabViewItem];
    [self syncTabButtons];
}

- (void) removeTabViewItem:(NSTabViewItem *)tabViewItem {
    [super removeTabViewItem: tabViewItem];
    [self syncTabButtons];
}

- (void) insertTabViewItem:(NSTabViewItem *)tabViewItem atIndex:(NSInteger)index {
    [super insertTabViewItem: tabViewItem atIndex: index];
    [self syncTabButtons];
}

- (void) setTabViewType: (NSTabViewType) aTabViewType {
    [super setTabViewType: NSNoTabsNoBorder];
    tabViewType = aTabViewType;
}

- (NSTabViewType) tabViewType {
    return tabViewType;
}


- (NSRect) contentRect {
    // Make room for tabButtons at the top:
    NSRect contentRect = self.bounds;
    contentRect.origin.y += 30.0;
    contentRect.size.height -= 34.0;
    return contentRect;
}

- (void) drawRect: (NSRect) dirtyRect {
	
    
    // Draw background, if set:
    CGRect frameRect = self.bounds;
    frameRect.origin.y += 20.0;
    frameRect.size.height -= 20.0;
    
    if (self.backgroundColor) {
        CGRect backgroundRect = NSIntersectionRect(dirtyRect, frameRect);
        [self.backgroundColor set];
        NSRectFill(backgroundRect);
    }
    
//    CGRect lineRect = self.bounds;
//    lineRect.origin.y += 20.0;
//    lineRect.size.height -= 21.0;

    // Draw line around content area:
    [[NSColor controlShadowColor] set];
    NSFrameRect(frameRect);
    
    //    [[NSColor lightGrayColor] set];
    //    NSRectFill(self.contentRect);
}

@end
