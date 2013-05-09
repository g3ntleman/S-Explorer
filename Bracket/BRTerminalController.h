//
//  BRTerminalController.h
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "OPVT100Emulator.h"

@interface BRTerminalController : NSViewController

@property (readonly) NSTask* task;
@property (readonly) OPVT100Emulator* terminalEmulator;


@end
