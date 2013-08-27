//
//  BRTerminalController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "BRREPLController.h"
#import "BRREPLView.h"
#import "PseudoTTY.h"

@implementation BRREPLController {

    PseudoTTY* tty;
}

static NSData* lineFeedData = nil;

+ (void) load {
    lineFeedData = [NSData dataWithBytes: "\n" length: 1];
}

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
}



- (void) taskOutputReceived: (NSNotification*) n {
    NSFileHandle* filehandle = n.object;
    //NSData* data = filehandle.availableData;
    NSData* data = n.userInfo[NSFileHandleNotificationDataItem];
    NSString* string = [[NSString alloc] initWithData: data encoding: NSISOLatin1StringEncoding];
    
    
    [self.replView appendString: string];
    
    [filehandle readInBackgroundAndNotify];
}

- (void) commitCommand: (NSString*) commandString {
    
    NSData* stringData = [commandString dataUsingEncoding: NSISOLatin1StringEncoding];
    [tty.masterFileHandle writeData: stringData];
    [tty.masterFileHandle writeData: lineFeedData];
}

- (BOOL) sendCurrentCommand {
    
    NSRange cursorRange = self.replView.selectedRange;
    NSRange commandRange;
    NSTextStorage* textStorage = self.replView.textStorage;
    if ([textStorage attribute: BKTextCommandAttributeName atIndex: cursorRange.location-1 effectiveRange: &commandRange]) {
        if (commandRange.length) {
            NSString* currentCommand = [textStorage.string substringWithRange: commandRange];
            NSLog(@"Sending command '%@'", currentCommand);
            
            [textStorage beginEditing];
            [textStorage replaceCharactersInRange:commandRange withString:@""];
            [textStorage endEditing];
            
            [self commitCommand: currentCommand];
            
            return YES;
        }
    }
    return NO;
}

- (IBAction) insertNewline: (id) sender {
    NSLog(@"Down key action.");
    [self sendCurrentCommand];
}


/**
 *
 */
- (IBAction) moveDown: (id) sender {
    NSLog(@"Down key action.");
}

/**
 *
 */
- (IBAction) moveUp: (id) sender {
    NSLog(@"Up key action.");
}

- (void) runCommand: (NSString*) command
      withArguments: (NSArray*) arguments
              error: (NSError**) errorPtr {
    
    NSAssert(! _task.isRunning, @"There is already a task (%@) running!", _task);
    
    command = [command stringByResolvingSymlinksInPath];
    
    if (! [[NSFileManager defaultManager] isExecutableFileAtPath:command]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain: @"org.cocoanuts.bracket" code: 404
                                        userInfo: @{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"No Executable file at '%@'", command]}];
        }
        return;
    }
    
    _task = [[NSTask alloc] init];
    
    tty = [[PseudoTTY alloc] init];
    
    [_task setStandardInput: tty.slaveFileHandle];
    [_task setStandardOutput: tty.slaveFileHandle];
    [_task setStandardError: tty.slaveFileHandle];
    [_task setArguments: arguments];
    [_task setLaunchPath: command];
    
    NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    [environment setObject: @"YES" forKey: @"NSUnbufferedIO"];
    [environment setObject: @"en_US-iso8859-1" forKey: @"LANG"];
    
    [_task setEnvironment: environment];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskOutputReceived:)
                                                 name:  NSFileHandleReadCompletionNotification
                                               object: tty.masterFileHandle];
    
    
    [tty.masterFileHandle readInBackgroundAndNotify];
    //[_task.standardError readInBackgroundAndNotify];
    
    [_task launch];
    
}

@end
