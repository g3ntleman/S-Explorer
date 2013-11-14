//
//  SEnREPLConnection.m
//  S-Explorer
//
//  Created by Dirk Theisen on 05.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEnREPLConnection.h"
#import "OPBEncoder.h"

@interface SEnREPLConnection () <NSStreamDelegate>

@property (strong, nonatomic) NSMutableDictionary* evaluationStatesByTag;
@property (readonly, nonatomic) NSInteger connectRetries;

@end

@implementation SEnREPLConnection

- (id) initWithHostname: (NSString*) hostname port: (NSInteger) port {
    if (self = [self init]) {
        _hostname = [hostname copy];
        _port = port;
        _evaluationStatesByTag = [[NSMutableDictionary alloc] initWithCapacity: 4];
        
        _socket = [[GCDAsyncSocket alloc] initWithDelegate: self delegateQueue: dispatch_get_main_queue()];
        _socket.delegate = self;
    }
    return self;
}

- (void) dealloc {
    [self close];
}

- (BOOL) openWithError: (NSError**) errorPtr {
    NSAssert(self.socket, @"openWithError: Socket not set.");
    NSAssert(self.socket.isDisconnected, @"openWithError: Socket still open. Close it first.");
    return [self.socket connectToHost: self.hostname onPort: self.port error: errorPtr];
}

- (void) close {
    if ([_socket isConnected]) {
        NSLog(@"Trying to disconnect %@", _socket);
        [_socket disconnect];
    }
    [_evaluationStatesByTag removeAllObjects];
    
}


- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"Connected to %@:%u.", host, port);
}

//- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
//    NSLog(@"Socket read %lu bytes.", (unsigned long)partialLength);
//
//
//    NSDictionary* result = (id)[OPBEncoder objectFromEncodedData: data];
//    if (result) {
//        SEnREplResultBlock block = [_blockOperationsByTag objectForKey: @(tag)];
//        block(result);
//    } else {
//        // Expect more Data:
//    }
//
//
//}

- (void) socketDidDisconnect: (GCDAsyncSocket*) sock withError: (NSError*) error {
    
    if (error.code == 61 && _connectRetries < 50) {
        // Connection Refused, retry for 50 times:
        _connectRetries += 1;
        [self performSelector: @selector(openWithError:) withObject: NULL afterDelay: 0.2];
    } else {
        NSLog(@"%@ disconnected (%@). Cleaning up...", self, error);
        [self close];
    }
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag: (long) tag {
    
    SEnREPLEvaluationState* evalState = _evaluationStatesByTag[@(tag)]; // expect this to exist
    
    NSAssert(evalState != nil, @"No evaluation state set up.");
    
    [evalState.buffer appendData: data];
    
    
    NSString* dataString = [[NSString alloc] initWithData: evalState.buffer encoding: NSUTF8StringEncoding];
    NSLog(@"Socket read data. Buffer now: %@", dataString);
    
    NSDictionary* result = (id)[OPBEncoder objectFromEncodedData: evalState.buffer];
    if (result) {
        evalState.buffer.length = 0; // Not entirely correct. Need to trim only parsed part (yet unknown).
        [evalState update: result];
        if (evalState.isEvaluationDone) {
            NSLog(@"Finished expression result for tag %ld", tag);
            evalState.resultBlock(evalState);
            return;
        }
    } else {
        
    }
    // Unable to parse the result, wait for more data:
    [self.socket readDataWithTimeout: 20.0 tag: tag]; // Warning, how do we know the timout the user wanted?
}

- (void) socket: (GCDAsyncSocket*) sock didWriteDataWithTag: (long) tag {
    NSLog(@"Socket wrote data for tag %ld.", (long)tag);
}

/**
 * Sends the encoded commandDictionary to the nREPL server process.
 * Calls the given block after decoding the result.
 * The timeout given is used for both, sending and receiving messages.
 * Returns the tag of the command.
 **/
- (long) sendCommandDictionary: (NSDictionary*) commandDictionary completionBlock: (SEnREplResultBlock) block timeout: (NSTimeInterval) timeout {
    
    // Block, until a connection is established, or failed:
    while (! (self.socket.isDisconnected || self.socket.isConnected)) {
        sleep(0.1);
    }
    
    NSData* benData = [[[OPBEncoder alloc] initForEncoding] encodeRootObject: commandDictionary];
    NSString* benString = [[NSString alloc] initWithData: benData encoding:NSUTF8StringEncoding];
    NSLog(@"Sending '%@'", benString);
    [self.socket writeData: benData withTimeout: timeout tag: _tagCounter];
    //[self.socket writeData: [GCDAsyncSocket LFData] withTimeout: timeout tag:_tagCounter];
    
    SEnREPLEvaluationState* evalState = [[SEnREPLEvaluationState alloc] initWithEvaluationID: [@(_tagCounter) description]
                                                                                   sessionID: nil // assigned automatically
                                                                                 resultBlock: block];
    [_evaluationStatesByTag setObject: evalState forKey: @(_tagCounter)];
    
    [self.socket readDataWithTimeout: timeout tag: _tagCounter];
    
    _tagCounter += 1;
    return _tagCounter-1;
}

- (long) evaluateExpression: (NSString*) expression completionBlock: (SEnREplResultBlock) block {
    
    NSDictionary* command = @{@"op": @"eval", @"code": expression, @"id": @(_tagCounter)};
    return [self sendCommandDictionary: command completionBlock: block timeout: 6.0];
}

@end

@interface SEnREPLEvaluationState () {
    NSMutableArray* _results;
    NSMutableData* _buffer;
}

@property (strong, nonatomic) NSString* status;
@property (strong, nonatomic) NSString* sessionID;
@property (strong, nonatomic) NSString* evaluationID;
@property (strong, nonatomic) SEnREplResultBlock resultBlock;


@end

@implementation SEnREPLEvaluationState

- (NSArray*) results {
    return _results;
}

- (NSMutableData*) buffer {
    if (!_buffer) {
        _buffer = [[NSMutableData alloc] init];
    }
    return _buffer;
}

- (BOOL) isEvaluationDone {
    return [self.status isEqualToString: @"done"];
}

- (id) initWithEvaluationID: (NSString*) anId
                  sessionID: (NSString*) aSessionID
                resultBlock: (SEnREplResultBlock) aResultBlock {
    if (self = [self init]) {
        self.evaluationID = anId;
        self.sessionID = aSessionID;
        self.resultBlock = aResultBlock;
    }
    return self;
}

- (void) update: (NSDictionary*) partialResultDictionary {
    
    NSArray* status = partialResultDictionary[@"status"];
    if (status) self.status = status.lastObject;
    
    NSString* sessionID = partialResultDictionary[@"session"];
    if (sessionID) self.sessionID = sessionID;
    
    NSString* result = partialResultDictionary[@"value"];
    if (result) {
        if (! _results) {
            _results = [[NSMutableArray alloc] init];
        }
        [_results addObject: result];
    }
}

@end
