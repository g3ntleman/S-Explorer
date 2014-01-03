//
//  OPTerminalView.h
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SEEditorTextView.h"

// extern NSString* BKTextCommandAttributeName;


//@protocol BRREPLDelegate <NSObject>
//
//- (void) commitCommand: (NSString*) command;
//- (NSString*) previousCommand; // may return nil
//- (NSString*) nextCommand; // max return nil
//
//@end

@interface SEREPLView : SEEditorTextView


@property (readonly) NSDictionary* interpreterAttributes;
@property (readonly) NSDictionary* commandAttributes;
@property (strong, nonatomic) NSString* prompt;
@property (strong, nonatomic) NSString* interpreterString;
@property (strong, nonatomic) NSFont* font;
@property (strong, nonatomic) NSString* command;
@property (readonly) NSRange interpreterRange;
@property (readonly) NSRange commandRange;
@property (readonly) NSRange promptRange;

- (BOOL) isCommandMode;

- (IBAction) clear: (id) sender;
- (void) appendInterpreterString: (NSString*) aString;


@end

