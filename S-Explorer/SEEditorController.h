//
//  SEEditorController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 16.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SESchemeParser.h"
#import "SEEditorTextView.h"
#import "NoodleLineNumberView.h"
#import "SESourceItem.h"

@interface SEEditorController : NSController <NSTextDelegate, NSTextViewDelegate>

@property (strong, nonatomic) IBOutlet SEEditorTextView* textEditorView;
@property (strong, nonatomic) NSArray* keywords; // sorted array
@property (strong, nonatomic) SESourceItem* sourceItem; // the source item to display


- (void) indentInRange: (NSRange) range;

- (NSRange) topLevelExpressionContainingLocation: (NSUInteger) location;

@end
