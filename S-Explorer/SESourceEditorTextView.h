//
//  SEEditorTextView.h
//  S-Explorer
//
//  Created by Dirk Theisen on 20.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NoodleLineNumberView.h"

@interface SESourceEditorTextView : NSTextView

@property (strong, nonatomic) IBOutlet NSPanel* gotoPanel;

@property (readonly) NSString* selectedString;
@property (nonatomic, strong) NoodleLineNumberView* lineNumberView;

@property (nonatomic, strong) NSSet* keywords; // for colorization

- (IBAction) expandSelection: (id) sender;
- (IBAction) contractSelection: (id) sender;
- (IBAction) selectSpecificLine: (id) sender;
- (IBAction) colorize: (id) sender;

- (void) colorizeRange: (NSRange) aRange;

- (IBAction) toggleComments: (id) sender; // implemented by the delegate

- (NSRange) selectLineNumber: (NSUInteger) line;

+ (NSColor*) commentColor;
+ (NSColor*) stringColor;
+ (NSColor*) numberColor;

@end

@interface  NSMutableAttributedString (SEExtensions)
- (void) markCharsAtRange: (NSRange) parRange;
- (void) unmarkChars;
@end


extern BOOL isOpeningPar(unichar aChar);
extern BOOL isClosingPar(unichar aChar);
extern unichar matchingPar(unichar aPar);
extern BOOL isPar(unichar aChar);


