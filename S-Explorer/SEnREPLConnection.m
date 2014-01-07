//
//  SEnREPLConnection.m
//  S-Explorer
//
//  Created by Dirk Theisen on 05.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEnREPLConnection.h"
#import "OPBEncoder.h"
#import "NSDictionary+OPImmutablility.h"

@interface SEnREPLConnection () <NSStreamDelegate>

@property (strong, nonatomic) NSMutableDictionary* evaluationStatesByTag;
@property (readonly, nonatomic) NSInteger connectRetries;
@property (strong, nonatomic) SEnREPLConnectBlock connectBlock;
@property (readonly, nonatomic) NSMutableData* readBuffer;

@end

@implementation SEnREPLConnection

/**
 * aSessionID may be nil. Will be assigned by the server with first reply.
 */
- (id) initWithHostname: (NSString*) hostname port: (NSInteger) port sessionID: (NSString*) aSessionID {
    if (self = [self init]) {
        _hostname = [hostname copy];
        _port = port;
        _evaluationStatesByTag = [[NSMutableDictionary alloc] initWithCapacity: 4];
        
        _socket = [[GCDAsyncSocket alloc] initWithDelegate: self delegateQueue: dispatch_get_main_queue()];
        _socket.delegate = self;
        _sessionID = [aSessionID copy];
        _readBuffer = [[NSMutableData alloc] init];
    }
    return self;
}

- (void) dealloc {
    [self close];
}

- (void) openWithConnectBlock: (SEnREPLConnectBlock) completionBlock {
    NSAssert(self.socket, @"openWithError: Socket not set.");
    NSAssert(self.socket.isDisconnected, @"openWithError: Socket still open. Close it first.");
    
    NSError* error = nil;
    self.connectBlock = completionBlock;
    
    if (_connectRetries <= 0) {
        _connectRetries = 50;
    }
    if (! [self.socket connectToHost: self.hostname onPort: self.port error: &error]) {
        self.connectBlock(self, error);
        self.connectBlock = nil;
    }
}

- (void) sendConsoleInput: (NSString*) inputString {
    NSParameterAssert(inputString.length);
    NSParameterAssert(NO);
}


- (void) close {
    
    void (^closeBlock)(NSDictionary* partialResult) = ^(NSDictionary* partialResult) {
        _connectRetries = 0;
        if ([_socket isConnected]) {
            NSLog(@"Trying to disconnect %@", _socket);
            [_socket disconnect];
        }
        [_evaluationStatesByTag removeAllObjects];
    };
    
    if ([_socket isConnected]) {
        if (self.sessionID.length) {
            NSLog(@"Closing The receiver session.");
            [self terminateSessionWithCompletionBlock: closeBlock];
        } else {
            closeBlock(nil);
        }
    }
}


- (void) socket: (GCDAsyncSocket*) sock didConnectToHost: (NSString*) host port: (UInt16) port {
    NSLog(@"%@ connected to %@:%u.", self, host, port);
    _connectRetries = 0;
    self.connectBlock(self, nil);
}

- (void) socketDidDisconnect: (GCDAsyncSocket*) sock withError: (NSError*) error {
    
    if (error.code == 61 && _connectRetries > 0) {
        // Connection Refused, Server not up (yet). Retry:
        _connectRetries -= 1;
        NSTimeInterval retryInterval = 0.3;
        NSLog(@"Connection Refused. Retrying in %.01fs. %ld tries left.", retryInterval, (long)_connectRetries);
        [self performSelector: @selector(openWithError:) withObject: NULL afterDelay: retryInterval];
    } else {
        self.connectBlock(self, error);
        NSLog(@"%@ disconnected (%@). Cleaning up...", self, error);
        [self close];
    }
}


- (void)socket: (GCDAsyncSocket*) sock didReadData: (NSData*) data withTag: (long) tag {
    
    /* tag is of no use and should be -1. */
    
    [self.readBuffer appendData: data];
    
    //NSString* dataString = [[NSString alloc] initWithData: self.readBuffer encoding: NSUTF8StringEncoding];
    //NSLog(@"Socket read data for tag %ld. Buffer now: %@", tag, dataString);
    
    
    NSDictionary* partialResultDictionary = (id)[OPBEncoder objectFromEncodedData: self.readBuffer];
    
    BOOL done = [[partialResultDictionary[@"status"] lastObject] isEqualToString: @"done"];

    // Test, if the dictionary is complete:
    if (partialResultDictionary) {
        
        NSNumber* requestNo = partialResultDictionary[@"id"];
        SEnREPLResultState* evalState = _evaluationStatesByTag[requestNo]; // expect this to exist

        NSAssert(evalState, @"No eval state found for partialResultDictionary %@", partialResultDictionary);
        
        NSLog(@"%@ received: %@ for requestNo %@", self, partialResultDictionary, requestNo);
        
        self.readBuffer.length = 0; // Not always correct. Need to trim only parsed part (yet unknown).
        
        NSString* sessionID = partialResultDictionary[@"session"];
        if (sessionID.length) _sessionID = sessionID;

        // Do not send the last message (for now). Remove this, if the terminating message is needed.
        if (! done) {
            evalState.partialResultBlock(partialResultDictionary);
        } else {
            // Cleanup:
            [_evaluationStatesByTag removeObjectForKey: requestNo];
        }
        
    }
    
    if (! done) {
        [self.socket readDataWithTimeout: -1 tag: -1];
    }
}

//- (void) socket: (GCDAsyncSocket*) sock didWriteDataWithTag: (long) tag {
//    NSLog(@"%@: Socket wrote data for tag %ld.", self, (long)tag);
//}

- (BOOL) isConnecting {
    return ! self.socket.isConnected && _connectRetries > 0;
}

/**
 * Sends the encoded commandDictionary to the nREPL server process.
 * Calls the given block after decoding the result.
 * The timeout given is used for both, sending and receiving messages.
 * Returns the tag of the command.
 **/
- (long) sendCommandDictionary: (NSDictionary*) commandDictionary completionBlock: (SEnREPLPartialResultBlock) block timeout: (NSTimeInterval) timeout {
    
    NSAssert([self.socket isConnected], @"Cannot send Command without open connection. -open first.");

    // This messes with the _tagCounter, so protect it:
    @synchronized(self) {
        // Does not work - getting unknown session error.
        if (_sessionID.length) {
            commandDictionary = [commandDictionary dictionaryBySettingObject: _sessionID forKey: @":session"];
        }
        
        NSData* benData = [[[OPBEncoder alloc] init] encodeRootObject: commandDictionary];
        //NSString* benString = [[NSString alloc] initWithData: benData encoding:NSUTF8StringEncoding];
        NSLog(@"%@ is sending '%@' for requestNo %ld", self, commandDictionary, _requestCounter);
        [self.socket writeData: benData withTimeout: timeout tag: _requestCounter];
        //[self.socket writeData: [GCDAsyncSocket LFData] withTimeout: timeout tag:_tagCounter];
        
        SEnREPLResultState* evalState = [[SEnREPLResultState alloc] initWithEvaluationID: [@(_requestCounter) description]
                                                                                 timeout: timeout
                                                                             resultBlock: block];
        [_evaluationStatesByTag setObject: evalState forKey: @(_requestCounter)];
        
        [self.socket readDataWithTimeout: timeout tag: -1];
        
        return _requestCounter++;
    }
}

/**
 * Returns the tag of the command.
 **/
- (long) evaluateExpression: (NSString*) expression completionBlock: (SEnREPLPartialResultBlock) block {
    NSParameterAssert(expression);
    NSDictionary* command = @{@"op": @"eval", @"code": expression, @"id": @(_requestCounter)};
    return [self sendCommandDictionary: command completionBlock: block timeout: 6.0];
}

//- (id) allSessionIDs {
//    __block NSString* sessionIDsString = nil;
//    NSDictionary* command = @{@"op": @"ls-sessions", @"id": @(_tagCounter)};
//    [self sendCommandDictionary: command completionBlock:^(NSDictionary *partialResult) {
//        sessionIDsString = partialResult[@"value"];
//    } timeout: 6.0];
//    
//    NSDate* start = [NSDate date];
//    
//    // Wait synchonously:
//    while (! sessionIDsString && [start timeIntervalSinceDate: start] < 6.0) {
//        NSLog(@"Waiting...");
//    	[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.2]];
//    }
//    return sessionIDsString;
//}


- (void) terminateSessionWithCompletionBlock: (SEnREPLPartialResultBlock) block {
    
    if (! _sessionID) {
        block(nil);
        return;
    }
    
    // NSLog(@"Closing The receiver session.");
    [self sendCommandDictionary: @{@"op": @"close", @"session": _sessionID}
                completionBlock: ^(NSDictionary* partialResult) {
                    block(partialResult);
                    _sessionID = nil;
                }
                        timeout: 2.0];
}


- (NSString*) description {
    return [NSString stringWithFormat: @"%@, session '%@'", [super description], self.sessionID];
}


@end

@interface SEnREPLResultState () {
    NSMutableArray* _results;
    NSMutableData* _buffer;
}

@property (strong, nonatomic) NSString* evaluationID;
@property (strong, nonatomic) SEnREPLPartialResultBlock partialResultBlock;


@end

@implementation SEnREPLResultState

- (NSArray*) results {
    return _results;
}

- (NSMutableData*) buffer {
    if (!_buffer) {
        _buffer = [[NSMutableData alloc] init];
    }
    return _buffer;
}


- (id) initWithEvaluationID: (NSString*) anId
                    timeout: (NSTimeInterval) timeoutSeconds
                resultBlock: (SEnREPLPartialResultBlock) aResultBlock {
    if (self = [self init]) {
        self.evaluationID = anId;
        self.partialResultBlock = aResultBlock;
        _timeout = timeoutSeconds;
    }
    return self;
}

//- (void) updateWithPartialResult: (NSDictionary*) partialResultDictionary {
//    
//    NSArray* status = partialResultDictionary[@"status"];
//    
//    if (status.count) {
//        self.status = status.lastObject;
//        
//        if ([self.status isEqualToString: @"error"]) {
//            _error = [[NSError alloc] initWithDomain: @"nREPL" code: -1 userInfo: @{NSLocalizedDescriptionKey: status.firstObject}];
//        } else {
//            _error = nil;
//        }
//    }
//    
//    NSString* sessionID = partialResultDictionary[@"session"];
//    if (sessionID) self.sessionID = sessionID;
//    
//    NSString* result = partialResultDictionary[@"value"];
//    if (result) {
//        if (! _results) {
//            _results = [[NSMutableArray alloc] init];
//        }
//        [_results addObject: result];
//    }
//    
//    //NSLog(@"Updated status with: %@ to %@", partialResultDictionary, self);
//
//}

@end
