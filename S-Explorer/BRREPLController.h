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

@property (readonly) NSRange currentCommandRange;
@property (readonly) NSString* currentCommand;
@property (strong) NSTask* task;

- (void) runCommand: (NSString*) command
      withArguments: (NSArray*) arguments
              error: (NSError**) errorPtr;
@end
