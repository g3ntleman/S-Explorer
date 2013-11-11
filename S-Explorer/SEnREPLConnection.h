//
//  SEnREPLConnection.h
//  S-Explorer
//
//  Created by Dirk Theisen on 05.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"


typedef void (^AuthorizationAsyncCallback)(OSStatus err, AuthorizationRights *blockAuthorizedRights);

typedef void (^SEnREplResultBlock)(NSDictionary* result);

@interface SEnREPLConnection : NSObject <GCDAsyncSocketDelegate>

@property (readonly, nonatomic) GCDAsyncSocket* socket;
@property (readonly, nonatomic) NSString* hostname;
@property (readonly, nonatomic) NSInteger port;
@property (readonly, nonatomic) NSInteger tagCounter;

- (id) initWithHostname: (NSString*) hostname port: (NSInteger) port;

- (long) sendCommandDictionary: (NSDictionary*) commandDictionary completionBlock: (void (^)(NSDictionary* result)) block timeout: (NSTimeInterval) timeout;

- (void) evaluateExpression: (NSString*) expression completionBlock: (void (^)(NSDictionary* result)) block;

- (BOOL) openWithError: (NSError**) errorPtr;
- (void) close;

@end
