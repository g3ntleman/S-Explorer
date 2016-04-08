//
//  SEnREPLConnection.m
//  S-Explorer
//
//  Created by Dirk Theisen on 05.11.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import "SEREPLConnection.h"
#import "NSDictionary+OPImmutablility.h"
#import <MPEdn/MPEdn.h>

@interface SEREPLConnection () <NSStreamDelegate>

@property (strong, nonatomic) NSMutableDictionary* evaluationStatesByTag;
@property (readonly, nonatomic) NSInteger connectRetries;
@property (strong, nonatomic) SEREPLConnectBlock connectBlock;
@property (readonly, nonatomic) NSMutableData* readBuffer;
@property (strong, readonly) NSMutableArray* resultBlocksQueue;

@end


@implementation SEREPLConnection

/**
 * aSessionID may be nil. Will be assigned by the server with first reply.
 */
- (id) initWithHostname: (NSString*) hostname port: (NSInteger) port {
    if (self = [self init]) {
        _hostname = [hostname copy];
        _port = port;
        _evaluationStatesByTag = [[NSMutableDictionary alloc] initWithCapacity: 4];
        
        _socket = [[GCDAsyncSocket alloc] initWithDelegate: self delegateQueue: dispatch_get_main_queue()];
        _socket.delegate = self;
        _readBuffer = [[NSMutableData alloc] init];
        _resultBlocksQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc {
    [self close];
}

- (void) openWithConnectBlock: (SEREPLConnectBlock) completionBlock {
    
    NSAssert(self.evaluationStatesByTag.count == 0, @"Looks like the connection %@ had been used before. Allocate a new connection each time.", self);
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
    
//    void (^closeBlock)(NSDictionary* partialResult) = ^(NSDictionary* partialResult) {
//        _connectRetries = 0;
//
//        [_evaluationStatesByTag removeAllObjects];
//    };
    
//    if ([_socket isConnected]) {
//        NSLog(@"Connection %@ will first close session.", self);
//        [self terminateSessionWithCompletion: closeBlock];
//        return;
//        closeBlock(nil);
//    }
    if ([self.socket isConnected]) {
        NSLog(@"Trying to disconnect %@", _socket);
        [self.socket disconnect];
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
        //self.connectBlock(self, error);
        NSLog(@"%@ disconnected (%@). Cleaning up...", self, error);
        [self close];
    }
}


- (void) socket: (GCDAsyncSocket*) sock didReadData: (NSData*) data withTag: (long) tag {
    
    /* tag is of no use and should be -1. */
    
    [self.readBuffer appendData: data];
    
    NSString* ednString = [[NSString alloc] initWithData: self.readBuffer encoding: NSUTF8StringEncoding];
    NSLog(@"Socket data read -> Buffer now: '%@'", ednString);
    
    // Try to parse the result as an edn dictionary:
    
    NSDictionary* ednDictionary = [ednString ednStringToObject];
    
    if (ednDictionary) {
        SEREPLResultBlock resultBlock = [self.resultBlocksQueue firstObject];
        if (resultBlock) {
            [self.resultBlocksQueue removeObjectAtIndex: 0];
            resultBlock(ednDictionary);
        }
    }
    
    //NSMutableDictionary* partialResultDictionary = [[OPBEncoder decoderForData: self.readBuffer mutableContainers: YES] decodeObject];
    
//    NSArray* status = partialResultDictionary[@"status"];
//    NSString* lastStatus = [status lastObject];
//    if ([lastStatus isEqualToString: @"error"]) {
//        NSLog(@"%@ received error: %@", self, status);
//        partialResultDictionary[@"NSError"] = [NSError errorWithDomain: @"org.cocoanuts.S-Explorer" code: -12 userInfo: @{NSLocalizedDescriptionKey: status[0]}]; // use all bust last array elements in description?
//    }
//    
//    
//    BOOL done = [lastStatus isEqualToString: @"done"];
//    
//    // Test, if the dictionary is complete:
//    if (partialResultDictionary) {
//        
//        NSNumber* requestNo = partialResultDictionary[@"id"];
//        SEnREPLResultState* evalState = _evaluationStatesByTag[requestNo]; // expect this to exist
//    }
    
    self.readBuffer.length = 0; // Not always correct. Need to trim only parsed part (yet unknown).
    
    
    // Do not send the last message (for now). Remove this, if the terminating message is needed.
    
}

//- (void) socket: (GCDAsyncSocket*) sock didWriteDataWithTag: (long) tag {
//    NSLog(@"%@: Socket wrote data for tag %ld.", self, (long)tag);
//}

- (BOOL) isConnecting {
    return ! self.socket.isConnected && _connectRetries > 0;
}

/**
 * Sends the EDN encoded expression to the REPL server process.
 * Calls the given block after decoding the result.
 * The timeout given is used for both, sending and receiving messages.
 * Returns the tag of the command.
 **/
- (long) sendExpression: (NSString*) expression timeout: (NSTimeInterval) timeout completion: (SEREPLResultBlock) resultBlock {
    
    NSAssert([self.socket isConnected], @"Cannot send Command without open connection. Call -[open] first.");

    // This messes with the _tagCounter, so protect it:
    @synchronized(self) {

        
        //NSData* benData = [[[OPBEncoder alloc] init] encodedDataFromObject: commandDictionary];
        //NSString* benString = [[NSString alloc] initWithData: benData encoding:NSUTF8StringEncoding];
        NSLog(@"%@ is sending '%@' as requestNo %ld", self, expression, _requestCounter);
        NSData* stringData = [expression dataUsingEncoding: NSUTF8StringEncoding];
        [self.socket writeData: stringData withTimeout: timeout tag: _requestCounter];
        //[self.socket writeData: [GCDAsyncSocket LFData] withTimeout: timeout tag:_tagCounter];
        [self.resultBlocksQueue addObject: resultBlock];
        
//        SEnREPLResultState* evalState = [[SEnREPLResultState alloc] initWithEvaluationID: [@(_requestCounter) description]
//                                                                                 timeout: timeout
//                                                                             resultBlock: block];
        
        [self.socket readDataWithTimeout: timeout tag: -1];
        
        return _requestCounter++;
    }
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@, port '%lu'", [super description], (unsigned long)self.port];
}


@end

//@interface SEnREPLResultState () {
//    NSMutableArray* _results;
//    NSMutableData* _buffer;
//}
//
//@property (strong, nonatomic) NSString* evaluationID;
//@property (strong, nonatomic) SEREPLResultBlock resultBlock;
//
//
//@end

//@implementation SEnREPLResultState
//
//- (NSArray*) results {
//    return _results;
//}
//
//- (NSMutableData*) buffer {
//    if (!_buffer) {
//        _buffer = [[NSMutableData alloc] init];
//    }
//    return _buffer;
//}
//
//
//- (id) initWithEvaluationID: (NSString*) anId
//                    timeout: (NSTimeInterval) timeoutSeconds
//                resultBlock: (SEREPLResultBlock) aResultBlock {
//    if (self = [self init]) {
//        self.evaluationID = anId;
//        self.resultBlock = aResultBlock;
//        _timeout = timeoutSeconds;
//    }
//    return self;
//}

//- (void) updateWithPartialResult: (NSDictionary*) partialResultDictionary {
//    
//    NSArray* status = partialResultDictionary[@"status"];
//    
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
//@end
