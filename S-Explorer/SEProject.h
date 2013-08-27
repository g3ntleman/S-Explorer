//
//  BRDocument.h
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BRREPLController.h"
#import "SESchemeParser.h"
#import "BRSourceItem.h"
#import "SEEditorController.h"

@class BRSourceItem;

@interface SEProject : NSDocument <NSOutlineViewDataSource, NSUserInterfaceValidations>

@property (strong, nonatomic) IBOutlet BRREPLController* replController;
@property (strong, nonatomic) IBOutlet NSView* sourceCellView;
@property (strong, nonatomic) IBOutlet NSImageView* sourceCellIconView;
@property (strong, nonatomic) IBOutlet NSTextField* sourceCellTextField;

@property (readonly) BRSourceItem* projectSourceItem;
@property (strong, nonatomic) NSDictionary* tabbedSourceItems;
@property (strong, nonatomic) IBOutlet NSSegmentedControl* sourceTab;
@property (strong, nonatomic) IBOutlet NSOutlineView* sourceList;
@property (strong, readonly) NSMutableDictionary* projectSettings;
@property (strong, readonly) NSMutableDictionary* uiSettings;
@property (strong, nonatomic) IBOutlet SEEditorController* editorController;

@property (strong, readonly) NSArray* availableLanguages; // NSArray of strings
@property (strong, nonatomic) NSString* currentLanguage;
@property (strong, readonly) NSDictionary* languageDictionary;

- (IBAction) selectSourceTab: (id) sender;
- (IBAction) sourceTableAction: (id) sender;
- (IBAction) saveCurrentSourceItem: (id) sender;
- (IBAction) revertCurrentSourceItemToSaved: (id) sender;

- (BRSourceItem*) currentSourceItem;



- (void) setSourceItem: (BRSourceItem*) item forIndex: (NSUInteger) index;

@end
