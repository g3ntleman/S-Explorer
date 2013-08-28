//
//  BRTerminalController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BRREPLView.h"
// #import "CSVM.h"


@interface BRREPLController : NSObject <NSCoding>

//@property (strong, nonatomic) IBOutlet NSResponder* keyResponder;

@property (strong, nonatomic) IBOutlet BRREPLView* replView;

@property (readonly) NSString* currentCommand;
@property (strong) NSTask* task;
@property (strong, readonly) NSString* commandString;
@property (strong, readonly) NSArray* commandArguments;
@property (strong, readonly) NSString* greeting;

@property (readonly) NSArray* previousCommands;
@property (readonly) NSArray* nextCommands;

- (void) setCommand: (NSString*) command
      withArguments: (NSArray*) arguments
           greeting: (NSString*) greeting
              error: (NSError**) errorPtr;

- (IBAction) run: (id) sender;


@end
