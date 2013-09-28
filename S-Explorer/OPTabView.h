//
//  OPTabView.h
//  OPTabView
//
//  Created by Dirk Theisen on 27.09.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OPTabView : NSTabView

@property (strong, nonatomic) NSColor* backgroundColor;
@property (readonly) NSSegmentedControl* tabButtons;

@end
