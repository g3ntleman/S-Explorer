//
//  SEEditorController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 16.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SESyntaxParser.h"
#import "SEEditorTextView.h"
#import "NoodleLineNumberView.h"
#import "SESourceItem.h"

/**
 * This Controller is responsible for controlling one SEEditorTextView.
 */
@interface SEEditorController : NSController <NSTextDelegate, NSTextViewDelegate>

@property (strong, nonatomic) IBOutlet SEEditorTextView* textEditorView;
@property (strong, nonatomic) NSArray* defaultKeywords; // sorted array (for prefix search)
@property (strong, nonatomic) NSArray* sortedKeywords; // sorted array (for prefix search)
@property (strong, nonatomic) SESourceItem* sourceItem; // the source item to display

- (void) indentInRange: (NSRange) range;

- (NSRange) topLevelExpressionContainingLocation: (NSUInteger) location;

- (IBAction) toggleComments: (id) sender;

@end
