//
//  BRTerminalController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import "SEREPLViewController.h"
#import "SEREPLView.h"
#import "SESyntaxParser.h"
#import "SESourceStorage.h"
#import "SEProjectDocument.h"

static const NSString* SEMainFunctionKey = @"MainFunction";

@interface SEREPLViewController ()
@property (nonatomic, readonly) NSMutableDictionary* settings;
@end


@implementation SEREPLViewController {
    
    NSMutableArray* _commandHistory;
}

@synthesize identifier;
@synthesize previousCommandHistoryIndex = _previousCommandHistoryIndex;


static NSData* lineFeedData = nil;

+ (void) load {
    lineFeedData = [NSData dataWithBytes: "\n" length: 1];
}

- (id) initWithProject: (SEProjectDocument*) aProject identifier: (NSString*) anIdentifier {
    if (self = [self init]) {
        _project = aProject;
        identifier = anIdentifier;
    }
    return self;
}


- (SEREPLView*) replView {
    return (SEREPLView*)self.textView;
}

- (NSMutableDictionary*) settings {
    return [self.project replSettingsForIdentifier: self.identifier];
}


- (NSArray*) commandHistory {
    
    if (! _commandHistory) {
        _commandHistory = [NSMutableArray arrayWithContentsOfURL: self.historyFileURL];
        if (! _commandHistory) {
            _commandHistory = [[NSMutableArray alloc] init];
        }
        _previousCommandHistoryIndex = _commandHistory.count-1;
    }

    return _commandHistory;
}


- (void) evaluateString: (NSString*) commandString {
    
    if (commandString.length) {
        NSParameterAssert(self.evalConnection.socket.isConnected);
        [self.evalConnection sendExpression: commandString timeout: 10.0 completion: ^(NSDictionary* partialResult) {
            NSLog(@"<-- Received %@ from nREPL.", [partialResult description]);
            NSString* output = partialResult[@"out"];
            if (output.length) {
                // Just log it:
                [self.replView appendInterpreterString: output];
            } else {
                NSString* resultValue = partialResult[@"value"];
                if (resultValue) {
                    NSRange range = self.replView.interpreterRange;
                    range.location = range.length;
                    range.length = resultValue.length;
                    [self.replView appendInterpreterString: resultValue];
                    [self.replView appendInterpreterString: @"\n"];
                    //NSLog(@"Colorizing '%@' ", [self.replView.string substringWithRange: range]);
                    [self.replView.textStorage colorizeRange: range symbols: nil defaultSymbols: nil];
                    
                } else {
                    NSString* errorString = partialResult[@"err"] ?: partialResult[@"ex"];
                    if (errorString) {
                        [self.replView appendInterpreterString: errorString];
                    } else {
                        NSString* lastStatus = [partialResult[@"status"] lastObject];
                        if (! [lastStatus isEqualToString: @"done"]) {
                            [self.replView appendInterpreterString: [partialResult description]];
                            [self.replView appendInterpreterString: @"\n"];
                        }

                    }
                }
            }
            
            [self.replView moveToEndOfDocument: self];
        }];
    }
}



- (NSURL*) historyFileURL {
    NSString* filename = [NSString stringWithFormat: @".REPL-History-%@.plist", @"1"];
    NSURL* resultURL = [[self.project.fileURL URLByDeletingLastPathComponent] URLByAppendingPathComponent: filename];
    return resultURL;
}

- (void) saveHistory {
    BOOL ok = [self.commandHistory writeToURL: self.historyFileURL atomically: YES];
    if (! ok) {
        NSLog(@"Warning: Unable to write command history to %@", self.historyFileURL);
    }
}

- (void) commitCurrentCommandToHistory {
    NSString* currentCommand = self.replView.command;
    if (currentCommand.length) {
        _previousCommandHistoryIndex = self.commandHistory.count;
        [_commandHistory addObject: currentCommand];
        [self saveHistory];
    }
}

// Clojure-Example how to list all synbols in clojure.utl:
// (keys (ns-publics 'clojure.core))

/**
 * Returns YES, if the command was sent.
 */
- (BOOL) sendCurrentCommand {
    
    if (! self.evalConnection.socket.isConnected) {
        NSLog(@"Warning, no connection to nREPL server.");
        NSBeep();
        // TODO: Insert NSAlert here, allowing server restart.
        return NO;
    }
    
    NSRange commandRange = self.replView.commandRange;
    if (commandRange.length) {
        NSLog(@"Sending command '%@'", self.replView.command);
        
        [self commitCurrentCommandToHistory];

        // Prune History:
        while (self.commandHistory.count > 100) {
            [_commandHistory removeObjectAtIndex: 0];
            _previousCommandHistoryIndex -= 1;
        }
        
        NSString* command = self.replView.command;
        [self.replView appendInterpreterString: self.replView.prompt];
        [self.replView appendInterpreterString: command];
        NSRange interpreterRange = self.replView.interpreterRange;
        NSRange commandRange = NSMakeRange(NSMaxRange(interpreterRange)-command.length, command.length);
        [self.replView.textStorage colorizeRange: commandRange symbols: nil defaultSymbols: nil];
        [self.replView appendInterpreterString: @"\n"];


        
        [self evaluateString: self.replView.command];
        self.replView.command = @"";

        return YES;
        
    } else {
        // Just insert an newline (and possibly scroll):
        [self.replView appendInterpreterString: @"\n"];
    }
    return NO;
}

- (IBAction) insertNewline: (id) sender {
    
    if (self.replView.isCommandMode) {
        //NSLog(@"Return key action.");
        [self sendCurrentCommand];
        [self.replView moveToEndOfDocument: sender];
    } else {
        [self.replView moveToEndOfDocument: sender];
        //self.replView.selectedRange = NSMakeRange(self.replView.string.length-1, 0);
    }
}


/**
 *
 */
- (IBAction) moveDown: (id) sender {
    
    if (self.replView.isCommandMode) {
        //NSLog(@"History next action.");
        if (_previousCommandHistoryIndex+2 >= self.commandHistory.count) {
            NSString* lastHistoryEntry = [self.commandHistory lastObject];
            if ([self.replView.command isEqualToString: lastHistoryEntry]) {
                _previousCommandHistoryIndex = self.commandHistory.count-1;
                self.replView.command = @"";
                NSLog(@"%@", self.replView.textStorage);
                return;
            }
            NSBeep();
            return;
        }
        
        _previousCommandHistoryIndex += 1;
        self.replView.command = self.commandHistory[self.previousCommandHistoryIndex+1];
        
        //NSLog(@"History: %@, prev index %ld", self.commandHistory, previousCommandHistoryIndex);
        NSLog(@"%@", self.replView.textStorage);

        return;
    }
    [self.replView moveDown: sender];
}

- (NSInteger) previousCommandHistoryIndex {
    _previousCommandHistoryIndex = MIN(_previousCommandHistoryIndex, self.commandHistory.count-1);
    return _previousCommandHistoryIndex;
}

/**
 *
 */
- (IBAction) moveUp: (id) sender {
    
    if (self.replView.isCommandMode) {
        //NSLog(@"History prev action.");
        
        
        if (self.previousCommandHistoryIndex < 0) {
            NSBeep();
            return;
        }
        
        // Save current non-committed command in history:
        if (self.previousCommandHistoryIndex+1 == self.commandHistory.count) {
            NSString* command = self.replView.command;
            
            if (command.length && ! [self.commandHistory[self.previousCommandHistoryIndex] isEqualToString: command]) {
                [self commitCurrentCommandToHistory];
                _previousCommandHistoryIndex -= 1;
            }
        }

        
        self.replView.command = self.commandHistory[_previousCommandHistoryIndex];
        _previousCommandHistoryIndex -= 1;
        
        //NSLog(@"History: %@, prev index %ld", self.commandHistory, previousCommandHistoryIndex);
        
        [self.replView moveToEndOfDocument: self];
        
        NSLog(@"%@", self.replView.textStorage);
        return;
    }
    [self.replView moveUp: sender];
}


- (void) textDidChange: (NSNotification*) notification {
    
    // Move history pointer to most recent entry:
    _previousCommandHistoryIndex = self.commandHistory.count-1;
    NSRange commandRange = self.replView.commandRange;
    
    if (self.textView.selectedRange.location >= commandRange.location) {
        [self.replView.textStorage colorizeRange: commandRange symbols: nil defaultSymbols: nil];
    }
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
    
    if (! self.evalConnection.socket.isDisconnected) {
        [self.evalConnection close];
        self.replView.editable = NO;
    }
}

/**
 * The block will be called on connect, connection error 
 * or - after a connection has been established - on sudden disconnect.
 */
- (void) connectWithBlock: (SEREPLConnectBlock) connectBlock {
        
    [self stop: self];
    //NSAssert(! _task.isRunning, @"There is already a task (%@) running! Terminate it, prior to starting a new one.", _task);
    
    _evalConnection = [[SEREPLConnection alloc] init];
    [_evalConnection openWithHostname: @"localhost"
                                 port: self.project.replServer.port
                           completion: ^(SEREPLConnection *connection, NSError *error) {
                               self.textView.editable = !error;
                               if (error) {
                                   //NSLog(@"Connection to nREPL failed with error: %@", error);
                                   if (error.code != 49) {
                                       [self.replView appendInterpreterString: [NSString stringWithFormat: @"\nError with nREPL Connection: %@\n", error]];
                                   }
                                   // TODO: Show NSAlert here?
                               } else {
//                                   [connection sendExpression: @"(use 'clojure.repl)" timeout: 10.0 completion: ^(NSDictionary* resultDictionary) {
//                                       // _evalConnection established.
//                                       // Now connect the _controlConnection using the same sessionID:
//                                       NSLog(@"Eval Connection %@ established.", _evalConnection);
//                                       _controlConnection = [[SEREPLConnection alloc] initWithHostname: @"localhost" port: self.project.replServer.port];
//                                       [_controlConnection openWithConnectBlock:^(SEREPLConnection *connection, NSError *error) {
//                                           [connection sendExpression: @"nil" timeout: 10.0 completion: ^(NSDictionary* result) {
//                                               NSLog(@"Control connection %@ established.", connection);
//                                           }];
//                                       }];
//                                   }];
                                   
                                   self.replView.editable = YES;
                                   
                                   if (self.greeting) {
                                       [self.replView appendInterpreterString: @"\n\n"];
                                       [self.replView appendInterpreterString: self.greeting];
                                       [self.replView appendInterpreterString: @"\n\n"];
                                   }
                                   [self.replView moveToEndOfDocument: self];
                               }
                               connectBlock(connection, error);
                           }];

}

- (IBAction) run: (id) sender {
    [self connectWithBlock: ^(SEREPLConnection *connection, NSError *error) {
        // TODO: Launch Target.
        // TODO: Trigger UI Updates
    }];
}

- (IBAction) connectREPL: (id) sender {
    [self connectWithBlock: NULL];
}


- (IBAction) selectREPL: (id) sender {
    NSLog(@"REPL selected.");
}







@end
