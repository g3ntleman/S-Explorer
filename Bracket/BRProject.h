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

@interface BRProject : NSDocument <BRSchemeParserDelegate, NSOutlineViewDataSource>

@property (strong, nonatomic) IBOutlet BRREPLController* replController;
@property (strong, nonatomic) IBOutlet NSTextView* sourceTextView;
@property (readonly) BRSourceItem* projectSourceItem;
@property (strong, nonatomic) NSArray* tabbedSourceItems;


@end
