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

- (void) keyDown: (NSEvent*) theEvent {
    
    //NSLog(@"Key pressed: %@", theEvent);
    
    NSString* charactersString = [theEvent characters];
    NSData* inputData = [charactersString dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
    // Pipe keys entered by the user into the external task:
    [_inputPipe.fileHandleForWriting writeData: inputData];    
}

- (void) noteScreenSizeChanged {
    kill(self.task.processIdentifier, SIGWINCH);
}


- (void) taskOutputReceived: (NSNotification*) n {
    NSFileHandle* filehandle = n.object;
    //NSData* data = filehandle.availableData;
    NSData* data = n.userInfo[NSFileHandleNotificationDataItem];
    [self.terminalEmulator processedTextOut: data.bytes length: data.length];
    
    [filehandle readInBackgroundAndNotify];
}

- (void) runCommand: (NSString*) command withArguments: (NSArray*) arguments {
    
    NSAssert(! _task.isRunning, @"There is already a task %@ running!", _task);
    
    command = [command stringByResolvingSymlinksInPath];

    
    _task = [[NSTask alloc] init];
    //self.outputCache = [NSMutableData data];
    //mv_modes = [[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil];
    
    _outputPipe = [[NSPipe alloc] init];
    _errorPipe = [[NSPipe alloc] init];
    _inputPipe = [[NSPipe alloc] init];
    
    [_task setStandardInput: _inputPipe];
    [_task setStandardOutput: _outputPipe];
    [_task setStandardError: _outputPipe];
    //[_task setArguments: arguments];
    [_task setLaunchPath: command];
    
    NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [environment setObject:@"vt100" forKey:@"TERM"];
    
    [_task setEnvironment: environment];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskOutputReceived:)
                                                 name:  NSFileHandleReadCompletionNotification
                                               object: _outputPipe.fileHandleForReading];
     
    
    [_outputPipe.fileHandleForReading readInBackgroundAndNotify];
    [_errorPipe.fileHandleForReading readInBackgroundAndNotify];
    
    [_task launch];
    
//    fsync(_inputPipe.fileHandleForWriting.fileDescriptor);

}

@end
