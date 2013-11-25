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

@class SEProject;

@interface SEREPLViewController : NSObject <NSTextViewDelegate>

@property (strong, nonatomic) SEREPLView* replView;

@property (nonatomic, readonly) NSString* currentCommand;
@property (nonatomic, readonly) SEnREPLConnection* connection;
@property (nonatomic, strong, readonly) NSString* greeting;

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

@end
