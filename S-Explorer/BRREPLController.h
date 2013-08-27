//
//  BRTerminalController.h
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BRREPLView.h"
// #import "CSVM.h"


@interface BRREPLController : NSObject <NSCoding, BRREPLDelegate>

//@property (strong, nonatomic) IBOutlet NSResponder* keyResponder;

@property (strong, nonatomic) IBOutlet BRREPLView* replView;

@property (readonly) NSRange currentCommandRange;
@property (readonly) NSString* currentCommand;

// @property (strong) CSVM* virtualMachine;

@end
