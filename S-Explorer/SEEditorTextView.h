//
//  SEEditorTextView.h
//  S-Explorer
//
//  Created by Dirk Theisen on 20.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SEEditorTextView : NSTextView

@property (strong, nonatomic) IBOutlet NSPanel* gotoPanel;

- (IBAction) expandSelection: (id) sender;
- (IBAction) contractSelection: (id) sender;
- (IBAction) selectSpecificLine: (id) sender;
- (NSRange) selectLineNumber: (NSUInteger) line;

@end
