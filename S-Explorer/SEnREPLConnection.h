//
//  SEnREPLConnection.h
//  S-Explorer
//
//  Created by Dirk Theisen on 05.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@class SEnREPLEvaluationState;

typedef void (^AuthorizationAsyncCallback)(OSStatus err, AuthorizationRights *blockAuthorizedRights);

typedef void (^SEnREplResultBlock)(SEnREPLEvaluationState* evalState);

@interface SEnREPLEvaluationState : NSObject

@property (readonly, nonatomic) NSMutableData* buffer;
@property (readonly, nonatomic) NSString* status;
@property (readonly, nonatomic) NSError* error;
@property (readonly, nonatomic) NSString* sessionID;
@property (readonly, nonatomic) NSString* evaluationID;
@property (readonly, nonatomic) NSArray* results;
@property (readonly, nonatomic) SEnREplResultBlock resultBlock;
@property (readonly) BOOL isStatusDone;


- (id) initWithEvaluationID: (NSString*) anId
                  sessionID: (NSString*) aSessionID
                resultBlock: (SEnREplResultBlock) aResultBlock;

- (void) update: (NSDictionary*) partialResultDictionary;

@end

@interface SEnREPLConnection : NSObject <GCDAsyncSocketDelegate>

@property (readonly, nonatomic) GCDAsyncSocket* socket;
@property (readonly, nonatomic) NSString* hostname;
@property (readonly, nonatomic) NSString* sessionID;
@property (readonly, nonatomic) NSInteger port;
@property (readonly, nonatomic) NSInteger tagCounter;
@property (readonly, nonatomic) BOOL isConnecting;


- (id) initWithHostname: (NSString*) hostname port: (NSInteger) port sessionID: (NSString*) aSessionID;

- (long) sendCommandDictionary: (NSDictionary*) commandDictionary completionBlock: (SEnREplResultBlock) block timeout: (NSTimeInterval) timeout;

- (long) evaluateExpression: (NSString*) expression completionBlock: (SEnREplResultBlock) block;

- (void) terminateSessionWithCompletionBlock: (SEnREplResultBlock) block;

- (BOOL) openWithError: (NSError**) errorPtr;
- (void) close;

@end
