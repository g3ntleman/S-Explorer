//
//  BRTerminalController.m
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "BRTerminalController.h"
#import "OPTerminalView.h"

@implementation BRTerminalController {
    NSPipe* _outputPipe;
    NSPipe* _errorPipe;
    NSPipe* _inputPipe;
}

@synthesize terminalEmulator;

- (id) init {
    if (self = [super init]) {
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {

    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    
}

- (void) awakeFromNib {
    self.terminalEmulator.delegate = self.terminalView;
}

- (OPTerminalEmulator*) terminalEmulator {
    if (! terminalEmulator) {
        terminalEmulator = [[OPTerminalEmulator alloc] init];
    }
    return terminalEmulator;
}

- (void) noteScreenSizeChanged {
    kill(self.task.processIdentifier, SIGWINCH);
}


- (void) taskOutputReceived: (NSNotification*) n {
    NSFileHandle* filehandle = n.object;
    NSData* data = filehandle.availableData;
    [self.terminalEmulator processedTextOut: data.bytes length: data.length];
}

- (void) runCommand: (NSString*) command withArguments: (NSArray*) arguments {
    
    NSAssert(! _task.isRunning, @"There is already a task %@ running!", _task);
    
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
    
    NSDictionary* environment = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"vt100", @"TERM", nil];
    
    [_task setEnvironment: environment];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskOutputReceived:)
                                                 name: NSFileHandleDataAvailableNotification
                                               object: _outputPipe.fileHandleForReading];
     
    
    [_outputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    [_errorPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    
    [_task launch];

}

@end
