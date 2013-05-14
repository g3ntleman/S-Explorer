//
//  BRTerminalController.h
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BRREPLView.h"

@interface BRREPLController : NSObject <NSCoding, BRREPLDelegate>

@property (readonly) NSTask* task;

@property (strong, nonatomic) IBOutlet NSResponder* keyResponder;

@property (strong, nonatomic) IBOutlet BRREPLView* replView;

- (void) runCommand: (NSString*) command
      withArguments: (NSArray*) arguments
              error: (NSError**) errorPtr;

- (void) noteTerminalSizeChanged: (id) sender;

@end
