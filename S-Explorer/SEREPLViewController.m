
//
//  BRTerminalController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEREPLViewController.h"
#import "SEREPLView.h"
#import "SESyntaxParser.h"
#import "SEProject.h"

static const NSString* SEMainFunctionKey = @"MainFunction";

@interface SEREPLViewController ()
@property (nonatomic, readonly) NSMutableDictionary* settings;
@end


@implementation SEREPLViewController {

    NSMutableArray* commandHistory;
    NSInteger previousCommandHistoryIndex;
    
    NSUInteger currentOutputStart;
}

@synthesize replView;
@synthesize project;
@synthesize identifier;


static NSData* lineFeedData = nil;

+ (void) load {
    lineFeedData = [NSData dataWithBytes: "\n" length: 1];
}

- (id) initWithProject: (SEProject*) aProject identifier: (NSString*) anIdentifier {
    if (self = [self init]) {
        project = aProject;
        identifier = anIdentifier;
    }
    return self;
}


- (void) setReplView:(SEREPLView *) aReplView {
    replView = aReplView;
    replView.delegate = self;
}

- (NSMutableDictionary*) settings {
    return [self.project replSettingsForIdentifier: self.identifier];
}


- (NSArray*) commandHistory {
    
    if (! commandHistory) {
        commandHistory = [[NSMutableArray alloc] init];
    }

    return commandHistory;
}


- (void) evaluateString: (NSString*) commandString {
    
    if (commandString.length) {
        NSParameterAssert(self.connection.socket.isConnected);
        //        NSData* stringData = [commandString dataUsingEncoding: NSISOLatin1StringEncoding];
        //        [tty.masterFileHandle writeData: stringData];
        //        [tty.masterFileHandle writeData: lineFeedData];
        [self.connection evaluateExpression: commandString completionBlock:^(SEnREPLResultState *evalState) {
            for (NSString* result in evalState.results) {
                [self.replView appendInterpreterString: result];
                [self.replView appendInterpreterString: @"\n"];
            }
            
            NSString* outputString = self.replView.string;
            NSRange outputRange = NSMakeRange(currentOutputStart, outputString.length-currentOutputStart);
            
            NSLog(@"Colorizing '%@' ", [outputString substringWithRange: outputRange]);
            
            [self.replView colorizeRange: outputRange];
            [self.replView moveToEndOfDocument: self];
        }];
    }
}


- (NSString*) currentCommand {
    return [self.replView.string substringWithRange: self.replView.commandRange];
}

- (void) setCurrentCommand:(NSString *)currentCommand {
    
    NSTextStorage* textStorage = self.replView.textStorage;
    NSRange commandRange = self.replView.commandRange;
    [textStorage beginEditing];
    [textStorage replaceCharactersInRange: commandRange withString: currentCommand];
    commandRange.length = currentCommand.length;
    [textStorage setAttributes: self.replView.typingAttributes range: commandRange];
    [textStorage endEditing];
    
    // Place cursor behind new command:
    self.replView.selectedRange = NSMakeRange(commandRange.location+currentCommand.length, 0);
}

- (NSURL*) historyFileURL {
    NSString* filename = [NSString stringWithFormat: @".REPL-History-%@.plist", @"1"];
    NSString* path = [self.workingDirectory stringByAppendingPathComponent: filename];
    return [NSURL fileURLWithPath: path];
}

- (void) saveHistory {
    [self.commandHistory writeToURL: self.historyFileURL atomically: YES];
}

- (void) commitCurrentCommandToHistory {
    NSString* currentCommand = self.currentCommand;
    if (currentCommand.length) {
        previousCommandHistoryIndex = self.commandHistory.count;
        [commandHistory addObject: currentCommand];
        [self saveHistory];
    }
}

- (BOOL) sendCurrentCommand {
    
    if (! self.connection.socket.isConnected) {
        NSBeep();
        return NO;
    }
    
    NSRange commandRange = self.replView.commandRange;
    if (commandRange.length) {
        NSLog(@"Sending command '%@'", self.currentCommand);
        
        [self commitCurrentCommandToHistory];
        
        // Prune History:
        if (self.commandHistory.count > 50) {
            [commandHistory removeLastObject];
            previousCommandHistoryIndex -= 1;
        }
        
        [self evaluateString: self.currentCommand];
        self.currentCommand = @"";

        currentOutputStart = self.replView.string.length;
                
        return YES;
        
    } else if (self.replView.isCommandMode) {
        NSString* log = self.replView.string;
        NSRange promptRange = [log lineRangeForRange: self.replView.selectedRange];
        NSString* prompt = [log substringWithRange: promptRange];
        [self.replView appendInterpreterString: @"\n"];
        [self.replView appendInterpreterString: prompt];
    }
    
    return NO;
}

- (IBAction) insertNewline: (id) sender {
    //NSLog(@"Return key action.");
    [self sendCurrentCommand];
    [self.replView moveToEndOfDocument: sender];
    //[self.replView scrollRangeToVisible: self.replView.selectedRange];
}


/**
 *
 */
- (IBAction) moveDown: (id) sender {
    
    if (self.replView.isCommandMode) {
        //NSLog(@"History next action.");
        if (previousCommandHistoryIndex+2 >= self.commandHistory.count) {
            NSString* lastHistoryEntry = [self.commandHistory lastObject];
            if ([self.currentCommand isEqualToString: lastHistoryEntry]) {
                previousCommandHistoryIndex = self.commandHistory.count-1;
                self.currentCommand = @"";
                return;
            }
            NSBeep();
            return;
        }
        
        previousCommandHistoryIndex += 1;
        self.currentCommand = self.commandHistory[previousCommandHistoryIndex+1];
        
        //NSLog(@"History: %@, prev index %ld", self.commandHistory, previousCommandHistoryIndex);
        
        return;
    }
    [self.replView moveDown: sender];
}

/**
 *
 */
- (IBAction) moveUp: (id) sender {
    
    if (self.replView.isCommandMode) {
        //NSLog(@"History prev action.");
        
        if (previousCommandHistoryIndex < 0) {
            NSBeep();
            return;
        }
        
        // Save current non-committed command in history:
        if (previousCommandHistoryIndex+1 == self.commandHistory.count) {
            NSString* command = self.currentCommand;
            
            if (command.length && ! [self.commandHistory[previousCommandHistoryIndex] isEqualToString: command]) {
                [self commitCurrentCommandToHistory];
                previousCommandHistoryIndex -= 1;
            }
        }

        
        self.currentCommand = self.commandHistory[previousCommandHistoryIndex];
        previousCommandHistoryIndex -= 1;
        
        //NSLog(@"History: %@, prev index %ld", self.commandHistory, previousCommandHistoryIndex);
        
        [self.replView moveToEndOfDocument: self];
        
        return;
    }
    [self.replView moveUp: sender];
}



- (void) textDidChange: (NSNotification*) notification {
    
    //NSLog(@"REPL changed text.");
    
    // Move history pointer to most recent entry:
    previousCommandHistoryIndex = self.commandHistory.count-1;
}

//- (BOOL) textView: (NSTextView*) textView shouldChangeTextInRanges: (NSArray*) affectedRanges replacementStrings: (NSArray*) replacementStrings {
//    
//    if (self.task.isRunning) {
//        return YES;
//    }
//    NSBeep();
//    return NO;
//}



- (IBAction) stop: (id) sender {
    
    if (! self.connection.socket.isDisconnected) {
        [self.connection close];
    }
}


- (void) connectAndLaunchTarget: (BOOL) launch {

    NSError* error = nil;
    
    [self stop: self];
    //NSAssert(! _task.isRunning, @"There is already a task (%@) running! Terminate it, prior to starting a new one.", _task);

    [self.replView clear: self];
    currentOutputStart = 0;
    
    if (self.greeting) {
        [self.replView appendInterpreterString: self.greeting];
        [self.replView appendInterpreterString: @"\n\n"];
    }
    [self.replView moveToEndOfDocument: self];
    
    [self.replView setEditable: YES];
    
    _connection = [[SEnREPLConnection alloc] initWithHostname: @"localhost" port: self.project.nREPL.port sessionID: nil];
    [_connection openWithError: &error];

}

- (IBAction) run: (id) sender {
    [self connectAndLaunchTarget: YES];
}

- (IBAction) connectREPL: (id) sender {
    [self connectAndLaunchTarget: NO];
}


- (IBAction) selectREPL: (id) sender {
    NSLog(@"REPL selected.");
}





@end
