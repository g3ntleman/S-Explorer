//
//  BRTerminalController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SEREPLView.h"
#import "SEnREPLConnection.h"
#import "SEnREPL.h"
#import "SESourceTextViewController.h"

@class SEProject;

@interface SEREPLViewController : SESourceTextViewController

@property (readonly, nonatomic) SEREPLView* replView;

@property (nonatomic, readonly) SEnREPLConnection* evalConnection;
@property (nonatomic, readonly) SEnREPLConnection* controlConnection;
@property (nonatomic, strong) NSString* greeting;

@property (nonatomic, readonly) NSArray* commandHistory;
@property (nonatomic, readonly) NSInteger previousCommandHistoryIndex;
@property (nonatomic, readonly) NSString* identifier;
@property (nonatomic, readonly, weak) SEProject* project;


- (id) initWithProject: (SEProject*) aProject identifier: (NSString*) anIdentifier;

- (IBAction) run: (id) sender;

- (IBAction) selectREPL: (id) sender;

- (void) evaluateString: (NSString*) expression;

- (NSURL*) historyFileURL;

- (IBAction) connectREPL: (id) sender;

- (void) connectWithBlock: (SEnREPLConnectBlock) connectBlock;

@end
