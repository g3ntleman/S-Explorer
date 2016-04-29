//
//  SEREPLConnection.h
//  S-Explorer
//
//  Created by Dirk Theisen on 05.11.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@class SEREPLConnection;


typedef void (^SEREPLRequestBlock)();
typedef void (^SEREPLResultBlock)(NSDictionary* evalResult);

/**
 * Called on connect, but also on disconnect.
 */
typedef void (^SEREPLConnectBlock)(SEREPLConnection* connection, NSError* error);

@interface SEREPLConnection : NSObject <GCDAsyncSocketDelegate>

// USe CFStreamCreatePairWithSocketToHost instead?

@property (readonly, nonatomic) GCDAsyncSocket* socket;
@property (readonly, nonatomic) NSString* hostname;
@property (readonly, nonatomic) NSInteger port;
@property (readonly, nonatomic) NSInteger requestCounter;
@property (readonly, nonatomic) BOOL isConnecting;

extern const NSString* SEREPLKeyResult;
extern const NSString* SEREPLKeyStdErr;
extern const NSString* SEREPLKeyStdOut;
extern const NSString* SEREPLKeyException;

- (void) openWithHostname: (NSString*) hostname
                     port: (NSInteger) portNo
               completion: (SEREPLConnectBlock) completionBlock;

- (void) sendConsoleInput: (NSString*) inputString;

- (long) sendExpression: (NSString*) expression timeout: (NSTimeInterval) timeout completion: (SEREPLResultBlock) block;

- (void) close;

@end
