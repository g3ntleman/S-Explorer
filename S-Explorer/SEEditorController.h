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

@interface SEEditorController : NSController <SESchemeParserDelegate, NSTextDelegate, NSTextViewDelegate>

@property (strong, nonatomic) IBOutlet SEEditorTextView* textEditorView;
@property (strong, nonatomic) NSArray* keywords; // sorted array


- (IBAction) colorize: (id) sender;

- (IBAction) expandSelection: (id) sender;

@end
