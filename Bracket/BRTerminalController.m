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

#define ESC \e

- (void) keyDown: (NSEvent*) theEvent {
    
    NSData* inputData = nil;
    char* code = nil;

    //NSLog(@"Key pressed: %@", theEvent);
    
    switch ([theEvent keyCode]) {
        case NSLeftArrowFunctionKey:
            NSLog(@"Left behind.");
            code = "\e[D";
            break;
        case NSRightArrowFunctionKey:
            NSLog(@"Right as always!");
            code = "\e[C";
            break;
        case NSDownArrowFunctionKey: 
            NSLog(@"Downward is Heavenward");
            code = "\e[B";
            break;
        case NSUpArrowFunctionKey:
            NSLog(@"Up, up, and away!");
            code = "\e[A";
            break;
        default: {
            NSString* charactersString = [theEvent characters];
            inputData = [charactersString dataUsingEncoding: NSISOLatin1StringEncoding allowLossyConversion: YES];
            break;
        }
    }
    if (code) {
        inputData = [NSData dataWithBytes: code length: strlen(code)];
    }
    
    if (inputData) {
        // Pipe keys entered by the user into the external task:
        [_inputPipe.fileHandleForWriting writeData: inputData];
    }
}

- (void) noteTerminalSizeChanged: (id) sender {
    NSLog(@"Sending SIGWINCH to sub-process.");
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
    [environment setObject: [NSString stringWithFormat:@"%u", self.terminalView.terminalSize.columns]
                    forKey: @"COLUMNS"];
    [environment setObject: [NSString stringWithFormat:@"%u", self.terminalView.terminalSize.rows]
                    forKey: @"LINES"];
    [environment setObject: @"en_US-iso8859-1" forKey: @"LANG"];

    
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
