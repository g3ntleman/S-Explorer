//
//  BRTerminalController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SEREPLView.h"

@interface SEREPLController : NSObject <NSTextViewDelegate>

@property (strong, nonatomic) SEREPLView* replView;

@property (readonly) NSString* currentCommand;
@property (strong) NSTask* task;
@property (strong, readonly) NSString* commandString;
@property (strong, readonly) NSArray* commandArguments;
@property (strong, readonly) NSString* greeting;
@property (strong, readonly) NSString* workingDirectory;

@property (strong, readonly) NSArray* commandHistory;

- (void) setCommand: (NSString*) command
      withArguments: (NSArray*) arguments
   workingDirectory: (NSString*) workingDirectory
           greeting: (NSString*) greeting
              error: (NSError**) errorPtr;

- (IBAction) run: (id) sender;
- (IBAction)selectREPL:(id)sender;

- (BOOL) isRunning;
- (void) evaluateString: (NSString*) expression;

- (NSURL*) historyFileURL;


@end
