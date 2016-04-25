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
@property (strong, readonly) NSMutableArray* requestBlocksQueue;
@property BOOL isReady;

@end

MPEdnKeyword* SEREPLKeyResult;
MPEdnKeyword* SEREPLKeyStdErr;
MPEdnKeyword* SEREPLKeyStdOut;
MPEdnKeyword* SEREPLKeyException;

@implementation SEREPLConnection

@synthesize isReady = _isReady;

static NSData* LineFeed = nil;

+ (void)initialize {
    [super initialize];
    
    SEREPLKeyResult = [MPEdnKeyword keyword: @"result"];
    SEREPLKeyStdErr  = [MPEdnKeyword keyword: @"err"];
    SEREPLKeyStdOut = [MPEdnKeyword keyword: @"out"];
    SEREPLKeyException = [MPEdnKeyword keyword: @"exception"];
    LineFeed = [GCDAsyncSocket LFData];
}

/**
 * aSessionID may be nil. Will be assigned by the server with first reply.
 */
- (id) init {
    if (self = [super init]) {
        _evaluationStatesByTag = [[NSMutableDictionary alloc] initWithCapacity: 4];
        
        _socket = [[GCDAsyncSocket alloc] initWithDelegate: self delegateQueue: dispatch_get_main_queue()];
        _socket.delegate = self;
        _readBuffer = [[NSMutableData alloc] init];
        _resultBlocksQueue = [[NSMutableArray alloc] init];
        _requestBlocksQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc {
    [self close];
}

- (void) openWithHostname: (NSString*) hostname
                     port: (NSInteger) portNo
               completion: (SEREPLConnectBlock) completionBlock {
    
    _hostname = [hostname copy];
    _port = portNo;
    
    NSAssert(self.evaluationStatesByTag.count == 0, @"Looks like the connection %@ had been used before. Allocate a new connection each time.", self);
    NSAssert(self.socket, @"openWithError: Socket not set.");
    NSAssert(self.socket.isDisconnected, @"openWithError: Socket still open. Close it first.");
    
    NSError* error = nil;
    self.connectBlock = completionBlock;
    
    if (_connectRetries <= 0) {
        _connectRetries = 50;
    }
    if (! [self.socket connectToHost: self.hostname onPort: self.port error: &error]) {
        if (self.connectBlock) {
            self.connectBlock(self, error);
            self.connectBlock = nil;
        }
    }
}

- (void) sendConsoleInput: (NSString*) inputString {
    NSParameterAssert(inputString.length);
    NSParameterAssert(NO);
}


- (void) close {

    if ([self.socket isConnected]) {
        NSLog(@"Trying to disconnect %@", _socket);
        [self.socket disconnect];
    }
}

- (void) processNextRequest {
    if (self.requestBlocksQueue.count) {
        SEREPLRequestBlock requestBlock = self.requestBlocksQueue.firstObject;
        [self.requestBlocksQueue removeObjectAtIndex: 0];
        self.isReady = NO;
        NSLog(@"Processing next expression.");
        requestBlock();
        [self.socket readDataWithTimeout: 10.0 tag: -1];
    }
}


- (BOOL) isReady {
    return _isReady;
}

- (void) setIsReady: (BOOL) isReady {
    if (isReady != _isReady) {
        _isReady = isReady;
        
        if (_isReady) {
            NSLog(@"REPL is ready.");
            [self processNextRequest];
        }
    }
}

- (NSTimeInterval) socket: (GCDAsyncSocket*) sock shouldTimeoutReadWithTag: (long) tag
                  elapsed: (NSTimeInterval) elapsed
                bytesDone: (NSUInteger) length {
    NSLog(@"REPL did not respond for %lf seconds. Waiting.", elapsed);
    return 1.0;
}


- (void) socket: (GCDAsyncSocket*) sock didConnectToHost: (NSString*) host port: (UInt16) port {
    NSLog(@"%@ connected to %@:%u.", self, host, port);
    _connectRetries = 0;
    
    [sock readDataWithTimeout: 10.0 tag: 0];
    
    if (self.connectBlock) {
        self.connectBlock(self, nil);
    }
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
    
    [self.readBuffer appendData: data];
    
    NSString* ednString = [[NSString alloc] initWithData: self.readBuffer encoding: NSUTF8StringEncoding];
    NSLog(@"Socket data read -> Buffer now: '%@'", ednString);
    
    if ([ednString hasSuffix: @"=> "]) {
        self.readBuffer.length = 0;
        self.isReady = YES;
    } else if ([ednString hasPrefix: @"{"] && [ednString hasSuffix: @"}\n"]) {
        // Try to parse the result as an edn dictionary:
        
        MPEdnParser* parser = [MPEdnParser new];
        parser.keywordsAsStrings = YES;
        NSDictionary* ednDictionary = [parser parseString: ednString];
        
        if ([ednDictionary isKindOfClass: [NSDictionary class]]) {
            SEREPLResultBlock resultBlock = [self.resultBlocksQueue firstObject];
            if (resultBlock) {
                [self.resultBlocksQueue removeObjectAtIndex: 0];
                resultBlock(ednDictionary);
            }
            
            self.readBuffer.length = 0; // might not be correct?
        } else {
            // Expect underfull buffer, continue reading.
            NSLog(@"Unable to parse. Partitial result? Continuing reading. (%@)", parser.error);
        }
    } else {
        // Expect incomplete data.
    }

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
    
    if (expression) {
        expression = [expression stringByAppendingString: @"\n"];
        SEREPLRequestBlock requestBlock = ^void() {
            NSLog(@"%@ is sending '%@' as request# %ld.", self, expression, _requestCounter);
            NSData* stringData = [expression dataUsingEncoding: NSUTF8StringEncoding];
            [self.socket writeData: stringData withTimeout: timeout tag: _requestCounter];
            
            [self.resultBlocksQueue addObject: resultBlock];
        };
        [self.requestBlocksQueue addObject: requestBlock];
    }
    
    [self.socket readDataWithTimeout: timeout tag: _requestCounter];
    
    return _requestCounter++;
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@ (port '%lu', %lu queued requests)", [super description], (unsigned long)self.port, (unsigned long)self.requestBlocksQueue.count];
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




