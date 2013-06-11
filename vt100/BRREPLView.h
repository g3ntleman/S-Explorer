//
//  OPTerminalView.h
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>

extern NSString* BKTextCommandAttributeName;


typedef struct {
    uint32 rows;
    uint32 columns;
} OPCharSize;

typedef struct {
    uint32 row;
    uint32 column;
} OPCharPosition;

@protocol BRREPLDelegate <NSObject>

- (void) commitCommand: (NSString*) command;
- (NSString*) previousCommand; // may return nil
- (NSString*) nextCommand; // max return nil

@end

@interface BRREPLView : NSTextView


@property (readonly) NSDictionary* commandAttributes;

@property (strong, nonatomic) NSFont* font;
@property (strong, nonatomic) IBOutlet id <BRREPLDelegate> replDelegate;


- (void) appendString: (NSString*) aString;

@end

