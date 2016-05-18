//
//  SEEditorController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 16.08.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SESyntaxParser.h"
#import "SESourceEditorTextView.h"
#import "NoodleLineNumberView.h"
#import "SESourceItem.h"
#import "SESourceTextViewController.h"


/**
 * This Controller is responsible for controlling one SEEditorTextView.
 */
@interface SESourceEditorController : SESourceTextViewController 

@property (strong, nonatomic) NSSet* defaultKeywords; // sorted array (for prefix search)
@property (strong, nonatomic) NSOrderedSet* sortedKeywords; // sorted array (for fast prefix search)
@property (weak, nonatomic) SESourceItem* sourceItem; // the source item to display

- (void) indentInRange: (NSRange) range;

- (NSRange) topLevelExpressionContainingLocation: (NSUInteger) location;

- (IBAction) toggleComments: (id) sender;

@end
