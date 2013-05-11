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
    unsigned rows;
    unsigned columns;
} OPCharSize;

typedef struct {
    unsigned row;
    unsigned column;
} OPCharPosition;

@interface OPTerminalView : NSView <OPTerminalEmulatorDelegate>

@property (strong, nonatomic) IBOutlet NSResponder* keyResponder;

@property (readonly) OPCharSize terminalSize;

@property (strong, nonatomic) NSFont* font;

@property (readonly) OPCharPosition cursorPosition;

@end
