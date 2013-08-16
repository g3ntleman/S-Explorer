//
//  SEEditorController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 16.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SESchemeParser.h"

@interface SEEditorController : NSController <SESchemeParserDelegate, NSTextDelegate>

@property (strong, nonatomic) IBOutlet NSTextView* textEditorView;
@property (strong, nonatomic) NSArray* keywords; // sorted array


- (IBAction) colorize: (id) sender;

@end
