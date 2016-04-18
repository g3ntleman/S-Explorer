//
//  SEREPLConnection.h
//  S-Explorer
//
//  Created by Dirk Theisen on 05.11.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "MPEdnKeyword.h"

@class SEREPLConnection;


typedef void (^SEREPLResultBlock)(NSDictionary* partialResult);

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

extern const MPEdnKeyword* SEREPLKeyResult;
extern const MPEdnKeyword* SEREPLKeyStdErr;
extern const MPEdnKeyword* SEREPLKeyStdOut;
extern const MPEdnKeyword* SEREPLKeyException;

- (id) initWithHostname: (NSString* _Nonnull ) hostname port: (NSInteger) port;

- (void) sendConsoleInput: (NSString*) inputString;

- (long) sendExpression: (NSString*) expression timeout: (NSTimeInterval) timeout completion: (SEREPLResultBlock) block;

- (void) openWithConnectBlock: (SEREPLConnectBlock) completionBlock;

- (void) close;

@end
