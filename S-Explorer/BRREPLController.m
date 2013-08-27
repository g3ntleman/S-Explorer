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
    
    
    [self appendString: string];
    
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
    if (self.replView.isCommandMode) {
        NSLog(@"History action.");
        return;
    }
    [self.replView moveDown: sender];
}

/**
 *
 */
- (IBAction) moveUp: (id) sender {
    if (self.replView.isCommandMode) {
    NSLog(@"History action.");
        return;
    }
    [self.replView moveUp: sender];
}


- (void) appendString:(NSString *)aString {
    
    NSTextStorage* textStorage = self.replView.textStorage;
    
    //self.typingAttributes = self.interpreterAttributes;
    
    [textStorage beginEditing];
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString: aString attributes: self.replView.interpreterAttributes];
    [textStorage replaceCharactersInRange: NSMakeRange(textStorage.string.length, 0)
                     withAttributedString: attributedString];
    //[textStorage replaceCharactersInRange: NSMakeRange(textStorage.string.length, 0) withString: aString];
    
    [textStorage endEditing];
}

- (IBAction) clear: (id) sender {
    
    self.replView.string = @"";
    
}

- (IBAction) stop: (id) sender {
    
    if (self.task) {
        
         [_task terminate];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: NSFileHandleReadCompletionNotification
                                                      object: tty.masterFileHandle];
        _task = nil;
    }
}

- (IBAction) run: (id) sender {
    

    [self stop: sender];
    //NSAssert(! _task.isRunning, @"There is already a task (%@) running! Terminate it, prior to starting a new one.", _task);

    [self clear: sender];
    
    if (self.greeting) {
        [self appendString: self.greeting];
        [self appendString: @"\n\n"];
    }
    [self.replView moveToEndOfDocument: self];
    
    _task = [[NSTask alloc] init];
    
    if (! tty) {
        tty = [[PseudoTTY alloc] init];
    }
    
    [_task setStandardInput: tty.slaveFileHandle];
    [_task setStandardOutput: tty.slaveFileHandle];
    [_task setStandardError: tty.slaveFileHandle];
    _task.arguments = self.commandArguments;
    _task.launchPath = self.commandString;
    
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
    
    //    _task.terminationHandler =  ^void (NSTask* task) {
    //        if (task == _task) {
    //            _task = nil;
    //        }
    //    };
    
    [_task launch];
}

- (void) setCommand: (NSString*) command
      withArguments: (NSArray*) arguments
           greeting: (NSString*) greeting
              error: (NSError**) errorPtr {

    _commandString = [command stringByResolvingSymlinksInPath];
    _commandArguments = arguments;
    _greeting = greeting;
    
    if (! [[NSFileManager defaultManager] isExecutableFileAtPath: command]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain: @"org.cocoanuts.bracket" code: 404
                                        userInfo: @{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"No Executable file at '%@'", command]}];
        }
        return;
    }
}



@end
