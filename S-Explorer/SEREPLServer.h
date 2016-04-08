//
//  SEREPL.h
//  S-Explorer
//
//  Created by Dirk Theisen on 10.11.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SEREPLServer;

typedef void (^SEREPLServerCompletionBlock)(SEREPLServer* repl, NSError* error);


@interface SEREPLServer : NSObject

@property (nonatomic, readonly) NSTask* task;

@property (nonatomic, strong) NSDictionary* settings;

@property (readonly, nonatomic) in_port_t port; // the network port on localhost, where clients can connect to

- (id) initWithSettings: (NSDictionary*) initialSettings;

- (void) startWithCompletion: (SEREPLServerCompletionBlock) block;
- (void) stop;

@end
