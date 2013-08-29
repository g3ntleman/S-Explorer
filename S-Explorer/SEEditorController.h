//
//  SEEditorController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 16.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SESchemeParser.h"
#import "SEEditorTextView.h"
#import "NoodleLineNumberView.h"

@interface SEEditorController : NSController <NSTextDelegate, NSTextViewDelegate>

@property (strong, nonatomic) IBOutlet SEEditorTextView* textEditorView;
@property (strong, nonatomic) NSArray* keywords; // sorted array
@property (strong, readonly) NoodleLineNumberView* lineNumberView;


- (IBAction) colorize: (id) sender;

- (IBAction) expandSelection: (id) sender;

- (void) indentInRange: (NSRange) range;

@end
