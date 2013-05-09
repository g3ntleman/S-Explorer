//
//  BRTerminalController.m
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "BRTerminalController.h"

@implementation BRTerminalController {
    NSPipe* _outputPipe;
    NSPipe* _errorPipe;
    NSPipe* _inputPipe;
}

- (id) init {
    if (self = [super init]) {
        _terminalEmulator = [[OPVT100Emulator alloc] init];
    }
    return self;
}

- (void) loadView {
    [super loadView];
    NSAssert([self.view conformsToProtocol:@protocol(OPVT100EmulatorDelegate)], @"View must conform to OPVT100EmulatorDelegate Protocol.");
    self.terminalEmulator.delegate = (id <OPVT100EmulatorDelegate>) self.view;
}

- (void) taskOutputReceived: (NSNotification*) n {
    NSFileHandle* filehandle = n.object;
    NSData* data = filehandle.availableData;
    [_terminalEmulator processedTextOut: data.bytes length: data.length];
}

- (void) runCommand: (NSString*) command withArguments: (NSArray*) arguments {
    
    _task = [[NSTask alloc] init];
    //self.outputCache = [NSMutableData data];
    //mv_modes = [[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil];
    
    _outputPipe = [[NSPipe alloc] init];
    _errorPipe = [[NSPipe alloc] init];
    _inputPipe = [[NSPipe alloc] init];
    
    [_task setStandardInput: _inputPipe];
    [_task setStandardOutput: _outputPipe];
    [_task setStandardError: _errorPipe];
    [_task setArguments: arguments];
    [_task setLaunchPath: command];
    
    [_task launch];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskOutputReceived:)
                                                 name: NSFileHandleDataAvailableNotification
                                               object: _outputPipe.fileHandleForReading];
     
    
    [_outputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    [_errorPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
}

@end
