//
//  BRTerminalController.h
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "OPTerminalEmulator.h"
#import "OPTerminalView.h"

@interface BRTerminalController : NSResponder <NSCoding>

@property (readonly) NSTask* task;
@property (readonly) OPTerminalEmulator* terminalEmulator;

@property (strong, nonatomic) IBOutlet NSResponder* keyResponder;

@property (strong, nonatomic) IBOutlet OPTerminalView* terminalView;

- (void) runCommand: (NSString*) command withArguments: (NSArray*) arguments;

@end
