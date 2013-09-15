//
//  BRTerminalController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SEREPLView.h"

@class SEProject;

@interface SEREPLController : NSObject <NSTextViewDelegate>

@property (strong, nonatomic) SEREPLView* replView;

@property (nonatomic, readonly) NSString* currentCommand;
@property (nonatomic, strong) NSTask* task;
@property (nonatomic, strong, readonly) NSString* commandString;
@property (nonatomic, strong, readonly) NSArray* commandArguments;
@property (nonatomic, strong, readonly) NSString* greeting;
@property (nonatomic, strong, readonly) NSString* workingDirectory;

@property (nonatomic, readonly) NSArray* commandHistory;
@property (nonatomic, readonly) NSString* identifier;
@property (nonatomic, readonly, weak) SEProject* project;


- (id) initWithProject: (SEProject*) aProject identifier: (NSString*) anIdentifier;

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
