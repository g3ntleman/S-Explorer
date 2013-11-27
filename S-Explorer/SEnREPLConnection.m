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
    }
    return self;
}

- (void) dealloc {
    [self close];
}

- (BOOL) openWithError: (NSError**) errorPtr {
    NSAssert(self.socket, @"openWithError: Socket not set.");
    NSAssert(self.socket.isDisconnected, @"openWithError: Socket still open. Close it first.");
    if (_connectRetries <= 0) {
        _connectRetries = 50;
    }
    return [self.socket connectToHost: self.hostname onPort: self.port error: errorPtr];
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
    NSLog(@"Connected to %@:%u.", host, port);
    _connectRetries = 0;
}

- (void) socketDidDisconnect: (GCDAsyncSocket*) sock withError: (NSError*) error {
    
    if (error.code == 61 && _connectRetries > 0) {
        // Connection Refused, retry:
        _connectRetries -= 1;
        NSTimeInterval retryInterval = 0.3;
        NSLog(@"Connection Refused. Retrying in %.01fs. %ld tries left.", retryInterval, (long)_connectRetries);
        [self performSelector: @selector(openWithError:) withObject: NULL afterDelay: retryInterval];
    } else {
        NSLog(@"%@ disconnected (%@). Cleaning up...", self, error);
        [self close];
    }
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag: (long) tag {
    
    NSNumber* tagNumber = @(tag);
    SEnREPLResultState* evalState = _evaluationStatesByTag[tagNumber]; // expect this to exist
    
    NSAssert(evalState != nil, @"No evaluation state set up.");
    
    [evalState.buffer appendData: data];
    
    
    NSString* dataString = [[NSString alloc] initWithData: evalState.buffer encoding: NSUTF8StringEncoding];
    NSLog(@"Socket read data for tag %ld. Buffer now: %@", tag, dataString);
    
    NSDictionary* partialResultDictionary = (id)[OPBEncoder objectFromEncodedData: evalState.buffer];
    if (partialResultDictionary) {
        evalState.buffer.length = 0; // Not entirely correct. Need to trim only parsed part (yet unknown).
        evalState.partialResultBlock(partialResultDictionary);
        
        NSString* sessionID = partialResultDictionary[@"session"];
        if (sessionID.length) _sessionID = sessionID;
    }
    if ([[partialResultDictionary[@"status"] lastObject] isEqualToString: @"done"]) {
        [_evaluationStatesByTag removeObjectForKey: tagNumber];
    } else {
        [self.socket readDataWithTimeout: 20.0 tag: tag]; // Warning, how do we know the timout the user wanted?
    }
}

- (void) socket: (GCDAsyncSocket*) sock didWriteDataWithTag: (long) tag {
    NSLog(@"Socket wrote data for tag %ld.", (long)tag);
}

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

// Does not work - getting unknown session error.
//    if (_sessionID.length) {
//        commandDictionary = [commandDictionary dictionaryBySettingObject: _sessionID forKey: @"session"];
//    }
    
    NSData* benData = [[[OPBEncoder alloc] init] encodeRootObject: commandDictionary];
    //NSString* benString = [[NSString alloc] initWithData: benData encoding:NSUTF8StringEncoding];
    NSLog(@"Sending '%@'", commandDictionary);
    [self.socket writeData: benData withTimeout: timeout tag: _tagCounter];
    //[self.socket writeData: [GCDAsyncSocket LFData] withTimeout: timeout tag:_tagCounter];
    
    SEnREPLResultState* evalState = [[SEnREPLResultState alloc] initWithEvaluationID: [@(_tagCounter) description]
                                                                                 resultBlock: block];
    [_evaluationStatesByTag setObject: evalState forKey: @(_tagCounter)];
    
    [self.socket readDataWithTimeout: timeout tag: _tagCounter];
    
    return _tagCounter++;
}

- (long) evaluateExpression: (NSString*) expression completionBlock: (SEnREPLPartialResultBlock) block {
    
    NSDictionary* command = @{@"op": @"eval", @"code": expression, @"id": @(_tagCounter)};
    return [self sendCommandDictionary: command completionBlock: block timeout: 6.0];
}


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
                resultBlock: (SEnREPLPartialResultBlock) aResultBlock {
    if (self = [self init]) {
        self.evaluationID = anId;
        self.partialResultBlock = aResultBlock;
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
