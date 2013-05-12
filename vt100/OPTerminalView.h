//
//  OPTerminalView.h
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "OPTerminalEmulator.h"

typedef struct {
    uint32 rows;
    uint32 columns;
} OPCharSize;

typedef struct {
    uint32 row;
    uint32 column;
} OPCharPosition;

@interface OPTerminalView : NSView <OPTerminalEmulatorDelegate>

@property (strong, nonatomic) IBOutlet NSResponder* keyResponder;

@property (readonly) OPCharSize terminalSize;

@property (strong, nonatomic) NSFont* font;

@property (readonly) OPCharPosition cursorPosition;

@end
