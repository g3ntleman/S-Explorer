//
//  BRTerminalController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SEREPLView.h"
#import "SEnREPLConnection.h"
#import "SEREPLServer.h"
#import "SESourceTextViewController.h"

@class SEProjectDocument;

@interface SEREPLViewController : SESourceTextViewController

@property (readonly, nonatomic) SEREPLView* replView;

@property (nonatomic, readonly) SEnREPLConnection* evalConnection;
@property (nonatomic, readonly) SEnREPLConnection* controlConnection;
@property (nonatomic, strong) NSString* greeting;

@property (nonatomic, readonly) NSArray* commandHistory;
@property (nonatomic, readonly) NSInteger previousCommandHistoryIndex;
@property (nonatomic, readonly) NSString* identifier;
@property (nonatomic, readonly, weak) SEProjectDocument* project;


- (id) initWithProject: (SEProjectDocument*) aProject identifier: (NSString*) anIdentifier;

- (IBAction) run: (id) sender;

- (IBAction) selectREPL: (id) sender;

- (void) evaluateString: (NSString*) expression;

- (NSURL*) historyFileURL;

- (IBAction) connectREPL: (id) sender;

- (void) connectWithBlock: (SEnREPLConnectBlock) connectBlock;

- (BOOL) sendCurrentCommand;

@end
