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

NSString* SEREPLKeyResult    = @"result";
NSString* SEREPLKeyStdErr    = @"err";
NSString* SEREPLKeyStdOut    = @"out";
NSString* SEREPLKeyException = @"exception";

@implementation SEREPLConnection

@synthesize isReady = _isReady;

static NSData* LineFeed = nil;

+ (void)initialize {
    [super initialize];
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
    if (self.isReady && self.requestBlocksQueue.count) {
        SEREPLRequestBlock requestBlock = self.requestBlocksQueue.firstObject;
        self.isReady = NO;
        [self.requestBlocksQueue removeObjectAtIndex: 0];
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
    return 4.0;
}


- (void) socket: (GCDAsyncSocket*) sock didConnectToHost: (NSString*) host port: (UInt16) port {
    NSLog(@"%@ connected to %@:%u.", self, host, port);
    _connectRetries = 0;
    
    
    if (self.connectBlock) {
        self.connectBlock(self, nil);
    }
    
    self.isReady = YES;
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

- (void) socket: (GCDAsyncSocket*) socket didReadString: (NSString*) string {
    
    //NSLog(@"Socket string read: '%@'", string);
    
    if (! socket.isConnected) {
        return;
    }

    if ([string hasPrefix: @"{"] && [string hasSuffix: @"}"]) {
        // Try to parse the result as an edn dictionary:
        
        MPEdnCoder* ednCoder = [[MPEdnCoder alloc] init];
        NSDictionary* ednDictionary = [ednCoder parseString: string];
        
        if ([ednDictionary isKindOfClass: [NSDictionary class]]) {
            SEREPLResultBlock resultBlock = [self.resultBlocksQueue firstObject];
            if (resultBlock) {
                [self.resultBlocksQueue removeObjectAtIndex: 0];
                resultBlock(ednDictionary);
            }
            
            self.readBuffer.length = 0; // might not be correct?
            
            return;
        }
    }
}


- (void) socket: (GCDAsyncSocket*) sock didReadData: (NSData*) data withTag: (long) tag {
    
    // Find first LF char in data:
    const uint8* dataBytes = data.bytes;
    NSUInteger dataLength = data.length;
    
    for (NSUInteger dataPos = 0; dataPos<dataLength; dataPos++) {
        if (dataBytes[dataPos] == '\n') {
            [self.readBuffer appendBytes: dataBytes length: dataPos];
            NSString* string = [[NSString alloc] initWithData: self.readBuffer encoding: NSUTF8StringEncoding];
            [self socket: sock didReadString: string];
            self.readBuffer.length = 0;
            NSRange rest = NSMakeRange(dataPos+1, dataLength-dataPos-1);
            if (rest.length) {
                // Process more results already in the buffer:
                data = [data subdataWithRange: rest];
                [self socket: sock didReadData: data withTag: tag];
                return;
            }
            self.isReady = YES;
            return;
        }
    }
    // No NewLine found. Append to buffer and continue reading:
    [self.readBuffer appendData: data];
    
    NSLog(@"%@: Unable to parse line after %lu bytes. Partitial result? Continuing reading…", self, (unsigned long)self.readBuffer.length);
    [self.socket readDataWithTimeout: 10.0 tag: -1];
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
            
            NSLog(@"%@ is sending '%@' as request# %ld.", self, [expression substringToIndex: MIN(expression.length-1, 100)], _requestCounter++);
            NSData* stringData = [expression dataUsingEncoding: NSUTF8StringEncoding];
            [self.socket writeData: stringData withTimeout: timeout tag: _requestCounter];
            
            [self.resultBlocksQueue addObject: resultBlock];
        };
        [self.requestBlocksQueue addObject: requestBlock];
        [self processNextRequest];
        return _requestCounter;

    }
    return 0;
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@ (port '%lu', %lu queued requests)", [super description], (unsigned long)self.port, (unsigned long)self.requestBlocksQueue.count];
}


@end


