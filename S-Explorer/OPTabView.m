//
//  OPTabView.m
//  OPTabView
//
//  Created by Dirk Theisen on 27.09.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

/**
 *  Only Top Tabs are currently supported.
 */

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

- (void) positionTabButtons {
    [_tabButtons sizeToFit];
    CGRect tabButtonsFrame = _tabButtons.frame;
    tabButtonsFrame.origin.y = 7.0;
    tabButtonsFrame.origin.x = (self.frame.size.width - tabButtonsFrame.size.width) / 2.0;
    _tabButtons.frame = tabButtonsFrame;
}

- (void) syncTabButtons {
    _tabButtons.segmentCount = self.tabViewItems.count;
    [self.tabViewItems enumerateObjectsUsingBlock:^(NSTabViewItem* item, NSUInteger index, BOOL *stop) {
        [_tabButtons setLabel: item.label forSegment: index];
    }];
    _tabButtons.selectedSegment = [self.tabViewItems indexOfObject: self.selectedTabViewItem];
    _tabButtons.action = @selector(didSelectSegment:);
    _tabButtons.target = self;
    [self positionTabButtons];
}

- (void) setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    [self positionTabButtons];
}

- (NSControlTint) controlTint {
    return [self.tabButtons.cell controlTint];
}

- (NSControlSize) controlSize {
    return [self.tabButtons.cell controlSize];
}

- (void) setControlSize:(NSControlSize)controlSize {
    [self.tabButtons.cell setControlSize: controlSize];
}

- (void) setControlTint:(NSControlTint)controlTint {
    [self.tabButtons.cell setControlTint: controlTint];
}

- (void) awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [NSColor whiteColor];
    self.drawsBackground = YES;
    self.drawsBorder = YES;
    self.tabViewType = NSTopTabsBezelBorder;
    _tabButtons = [[NSSegmentedControl alloc] initWithFrame: NSZeroRect];
    [self syncTabButtons];
    
    for (NSTabViewItem* item in self.tabViewItems) {
        [item addObserver: self forKeyPath: @"label" options:0 context:nil];
    }
    
    [self addSubview: _tabButtons];
}

- (void) dealloc {
    for (NSTabViewItem* item in self.tabViewItems) {
        [item removeObserver:self forKeyPath:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[NSTabViewItem class]]) {
        [self.tabButtons setLabel: [object label] forSegment: [self indexOfTabViewItem: object]];
        [self positionTabButtons];
    }
}

/**
 * The segemented control sends this and we are adapting it:
 */
- (IBAction) didSelectSegment: (id) sender {
    [self selectTabViewItemAtIndex: [sender selectedSegment]];
}

- (void) addTabViewItem:(NSTabViewItem *)tabViewItem {
    [self insertTabViewItem:tabViewItem atIndex: self.numberOfTabViewItems];
}

- (void) removeTabViewItem:(NSTabViewItem *)tabViewItem {
    [super removeTabViewItem: tabViewItem];
    [tabViewItem removeObserver:self forKeyPath:@"label"];
    [self syncTabButtons];
}

- (void) insertTabViewItem:(NSTabViewItem *)tabViewItem atIndex:(NSInteger)index {
    [super insertTabViewItem: tabViewItem atIndex: index];
    [tabViewItem addObserver: self forKeyPath: @"label" options:0 context:nil];
    [self syncTabButtons];
}

- (void) setTabViewType: (NSTabViewType) aTabViewType {
    [super setTabViewType: NSNoTabsNoBorder];
    tabViewType = aTabViewType; // todo: use tabViewType to support bottom tabs.
}

- (NSTabViewType) tabViewType {
    return tabViewType;
}


- (NSRect) contentRect {
    // Make room for tabButtons at the top:
    NSRect contentRect = self.bounds;
    contentRect.origin.y += 30.0;
    contentRect.size.height -= 34.0;
    if (self.drawsBorder) {
        contentRect.origin.x += 1.0;
        contentRect.size.width -= 2.0;
    }
    return contentRect;
}

- (void)setNeedsLayout:(BOOL)flag {
    [super setNeedsLayout:flag];
}

- (BOOL) needsLayout {
    return [super needsLayout];
}


- (void) drawRect: (NSRect) dirtyRect {
	
    
    // Draw background, if set:
    CGRect frameRect = self.bounds;
    frameRect.origin.y += 19.0;
    frameRect.size.height -= 19.0;
    
    if (self.backgroundColor && self.drawsBackground) {
        CGRect backgroundRect = NSIntersectionRect(dirtyRect, frameRect);
        [self.backgroundColor set];
        NSRectFill(backgroundRect);
    }
    
//    CGRect lineRect = self.bounds;
//    lineRect.origin.y += 20.0;
//    lineRect.size.height -= 21.0;

    if (! self.drawsBorder) {
        frameRect.size.height = 1.0;
    }
    // Draw line around content area:
    [[NSColor controlShadowColor] set];
    NSFrameRect(frameRect);
    
    //    [[NSColor lightGrayColor] set];
    //    NSRectFill(self.contentRect);
}

- (BOOL)isOpaque {
    return NO;
}

//- (void) closeTab: (id) sender {
//	NSTabViewItem *item = [sender representedObject];
//    if ([self numberOfTabViewItems] == 1) {
//        return;
//    }
//    if ([[self delegate] respondsToSelector:@selector(tabView:shouldCloseTabViewItem:)]) {
//        if (![[self delegate] tabView:tabView shouldCloseTabViewItem: item]) {
//            return;
//        }
//    }
//    
//	[self removeTabViewItem: item];
//}

@end

@implementation NSTabView (OPTabView)

- (NSUInteger) indexOfSelectedTabViewItem {
    return [self indexOfTabViewItem: self.selectedTabViewItem];
}

@end
