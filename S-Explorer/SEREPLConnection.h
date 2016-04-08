//
//  SEnREPLConnection.h
//  S-Explorer
//
//  Created by Dirk Theisen on 05.11.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

//@class SEnREPLResultState;
@class SEREPLConnection;

//typedef void (^AuthorizationAsyncCallback)(OSStatus err, AuthorizationRights *blockAuthorizedRights);

typedef void (^SEREPLResultBlock)(NSDictionary* partialResult);

/**
 * Called on connect, but also on disconnect.
 */
typedef void (^SEREPLConnectBlock)(SEREPLConnection* connection, NSError* error);


//@interface SEnREPLResultState : NSObject
//
//@property (readonly, nonatomic) NSString* status;
//@property (readonly, nonatomic) NSError* error;
//@property (readonly, nonatomic) NSString* evaluationID;
//@property (readonly, nonatomic) NSArray* results;
//@property (readonly, nonatomic) SEREPLResultBlock resultBlock;
//@property (readonly) BOOL isStatusDone;
//@property (readonly) NSTimeInterval timeout;
//
//
//- (id) initWithEvaluationID: (NSString*) anId
//                    timeout: (NSTimeInterval) timeoutSeconds
//                resultBlock: (SEREPLResultBlock) aResultBlock;
//
//
//@end

@interface SEREPLConnection : NSObject <GCDAsyncSocketDelegate>

// USe CFStreamCreatePairWithSocketToHost instead?

@property (readonly, nonatomic) GCDAsyncSocket* socket;
@property (readonly, nonatomic) NSString* hostname;
@property (readonly, nonatomic) NSInteger port;
@property (readonly, nonatomic) NSInteger requestCounter;
@property (readonly, nonatomic) BOOL isConnecting;


- (id) initWithHostname: (NSString*) hostname port: (NSInteger) port;

- (void) sendConsoleInput: (NSString*) inputString;

- (long) sendExpression: (NSString*) expression timeout: (NSTimeInterval) timeout completion: (SEREPLResultBlock) block;

- (void) openWithConnectBlock: (SEREPLConnectBlock) completionBlock;

- (void) close;

@end
