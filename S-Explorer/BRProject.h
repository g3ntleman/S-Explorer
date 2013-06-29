//
//  BRDocument.h
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BRREPLController.h"
#import "BRSchemeParser.h"

@class BRSourceItem;

@interface BRProject : NSDocument <BRSchemeParserDelegate, NSOutlineViewDataSource, NSUserInterfaceValidations>

@property (strong, nonatomic) IBOutlet BRREPLController* replController;
@property (strong, nonatomic) IBOutlet NSTextView* sourceTextView;
@property (strong, nonatomic) IBOutlet NSView* sourceCellView;
@property (strong, nonatomic) IBOutlet NSImageView* sourceCellIconView;
@property (strong, nonatomic) IBOutlet NSTextField* sourceCellTextField;

@property (readonly) BRSourceItem* projectSourceItem;
@property (strong, nonatomic) NSDictionary* tabbedSourceItems;
@property (strong, nonatomic) IBOutlet NSSegmentedControl* sourceTab;
@property (strong, nonatomic) IBOutlet NSOutlineView* sourceList;
@property (strong, readonly) NSMutableDictionary* projectSettings;
@property (strong, readonly) NSMutableDictionary* uiSettings;

- (IBAction) selectSourceTab: (id) sender;
- (IBAction) sourceTableAction: (id) sender;
- (IBAction) saveCurrentSourceItem: (id) sender;
- (IBAction) revertCurrentSourceItemToSaved: (id) sender;

- (BRSourceItem*) currentSourceItem;


- (void) setSourceItem: (BRSourceItem*) item forIndex: (NSUInteger) index;

@end
