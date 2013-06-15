//
//  OPTabbedSeqmentedControl.h
//  WeSync
//
//  Created by Dirk Theisen on 15.05.07.
//  Copyright 2007 Objectpark Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OPTabbedSeqmentedControl : NSSegmentedControl {
	IBOutlet NSTabView* tabView;
	BOOL isDragging;
}

@end

@interface NSTabView (OPTriggerBySegmentedControl)

- (IBAction) selectTabFromSegmentedControl: (id) sender;

@end