//
//  BRTerminalController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SEREPLView.h"

@interface SEREPLController : NSObject

//@property (strong, nonatomic) IBOutlet NSResponder* keyResponder;

@property (strong, nonatomic) IBOutlet SEREPLView* replView;

@property (readonly) NSString* currentCommand;
@property (strong) NSTask* task;
@property (strong, readonly) NSString* commandString;
@property (strong, readonly) NSArray* commandArguments;
@property (strong, readonly) NSString* greeting;
@property (strong, readonly) NSString* workingDirectory;

@property (readonly) NSMutableArray* previousCommands;
@property (readonly) NSMutableArray* nextCommands;

- (void) setCommand: (NSString*) command
      withArguments: (NSArray*) arguments
   workingDirectory: (NSString*) workingDirectory
           greeting: (NSString*) greeting
              error: (NSError**) errorPtr;

- (IBAction) run: (id) sender;

- (NSURL*) historyFileURL;


@end
