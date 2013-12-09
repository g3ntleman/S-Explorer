//
//  SEnREPLConnection.h
//  S-Explorer
//
//  Created by Dirk Theisen on 05.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@class SEnREPLResultState;
@class SEnREPLConnection;

typedef void (^AuthorizationAsyncCallback)(OSStatus err, AuthorizationRights *blockAuthorizedRights);

typedef void (^SEnREPLPartialResultBlock)(NSDictionary* partialResult);
typedef void (^SEnREPLConnectionCompletionBlock)(SEnREPLConnection* connection, NSError* error);


@interface SEnREPLResultState : NSObject

@property (readonly, nonatomic) NSMutableData* buffer;
@property (readonly, nonatomic) NSString* status;
@property (readonly, nonatomic) NSError* error;
@property (readonly, nonatomic) NSString* evaluationID;
@property (readonly, nonatomic) NSArray* results;
@property (readonly, nonatomic) SEnREPLPartialResultBlock partialResultBlock;
@property (readonly) BOOL isStatusDone;


- (id) initWithEvaluationID: (NSString*) anId
                resultBlock: (SEnREPLPartialResultBlock) aResultBlock;


@end

@interface SEnREPLConnection : NSObject <GCDAsyncSocketDelegate>

@property (readonly, nonatomic) GCDAsyncSocket* socket;
@property (readonly, nonatomic) NSString* hostname;
@property (readonly, nonatomic) NSString* sessionID;
@property (readonly, nonatomic) NSInteger port;
@property (readonly, nonatomic) NSInteger tagCounter;
@property (readonly, nonatomic) BOOL isConnecting;


- (id) initWithHostname: (NSString*) hostname port: (NSInteger) port sessionID: (NSString*) aSessionID;

- (long) sendCommandDictionary: (NSDictionary*) commandDictionary completionBlock: (SEnREPLPartialResultBlock) block timeout: (NSTimeInterval) timeout;

- (void) sendConsoleInput: (NSString*) inputString;

- (long) evaluateExpression: (NSString*) expression completionBlock: (SEnREPLPartialResultBlock) block;

- (void) terminateSessionWithCompletionBlock: (SEnREPLPartialResultBlock) block;

- (void) openWithCompletion: (SEnREPLConnectionCompletionBlock) completionBlock;

- (void) close;

@end
