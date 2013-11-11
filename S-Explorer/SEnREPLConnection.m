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

@property (strong, nonatomic) NSMutableDictionary* blocksByTag;
@property (strong, nonatomic) NSMutableDictionary* buffersByTag;

@end

@implementation SEnREPLConnection

- (id) initWithHostname: (NSString*) hostname port: (NSInteger) port {
    if (self = [self init]) {
        _hostname = [hostname copy];
        _port = port;
        _blocksByTag = [[NSMutableDictionary alloc] initWithCapacity: 4];
        _buffersByTag = [[NSMutableDictionary alloc] initWithCapacity: 4];
        
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
        [_blocksByTag removeAllObjects];
        [_buffersByTag removeAllObjects];
    }
}

//- (void) stream: (NSStream *) stream handleEvent: (NSStreamEvent) eventCode {
//    // An NSStream delegate callback that's called when events happen on our
//    // network stream.
//    
//    NSLog(@"Got Stream Event %lu for %@", eventCode, stream);
//    
//    if (stream == _inputStream) {
//        switch (eventCode) {
//            case NSStreamEventOpenCompleted: {
//                NSLog(@"Opened connection.");
//            } break;
//            case NSStreamEventHasBytesAvailable: {
//                uint8_t buffer[2000];
//                NSInteger bufferUsed = [_inputStream read: buffer maxLength: sizeof(buffer)];
//                if (bufferUsed >= 0) {
//                    NSLog(@"inputStream read %ld bytes. Appending...", bufferUsed);
//                    [_readBuffer appendBytes: buffer length: bufferUsed];
//                    id result = [OPBEncoder objectFromEncodedData: _readBuffer];
//                    if (result) {
//                        NSLog(@"Command-result %@", result);
//                    }
//                } else {
//                    NSLog(@"Error Reading from %@: %@", self, _inputStream.streamError);
//                }
//            }
//            default: {
//                NSLog(@"Unhandled inputstream event. error %@", _inputStream.streamError);
//            }
//        }
//    } else {
//        NSLog(@"Unhandled outputStream event. error %@", _outputStream.streamError);
//    }
//}

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
    
    if (error.code == 61) {
        // Connection Refused, retry:
        sleep(0.05);
        [self openWithError: NULL];
    } else {
        NSLog(@"%@ disconnected (error %@).", self, error);
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    
    NSMutableData* buffer = _buffersByTag[@(tag)];
    
    NSAssert(buffer != nil, @"No buffer detected ");
    
    [buffer appendData: data];
    
    
    NSString* dataString = [[NSString alloc] initWithData: buffer encoding: NSUTF8StringEncoding];
    NSLog(@"Socket read data. Buffer now: %@", dataString);

    
    NSDictionary* result = (id)[OPBEncoder objectFromEncodedData: buffer];
    if (result) {
        
        SEnREplResultBlock block = [_blocksByTag objectForKey: @(tag)];
        block(result);
        [buffer setLength: 0];
        if ([result[@"status"] containsObject: @"done"]) {
            [_blocksByTag removeObjectForKey: @(tag)];
            NSLog(@"Finished expression result for tag %d", tag);
            return;
        }
    }
    // Unable to parse the result, wait for more data:
    [self.socket readDataWithTimeout: 2.0 tag: tag];
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
- (long) sendCommandDictionary: (NSDictionary*) commandDictionary completionBlock: (void (^)(NSDictionary* result)) block timeout: (NSTimeInterval) timeout {
    
    //NSAssert([self.socket isConnected], @"Cannot send Command without open connection. -open first.");
 
    NSData* benData = [[[OPBEncoder alloc] initForEncoding] encodeRootObject: commandDictionary];
    NSString* benString = [[NSString alloc] initWithData: benData encoding:NSUTF8StringEncoding];
    NSMutableData* buffer = [[NSMutableData alloc] init];
    NSLog(@"Sending '%@'", benString);
    [self.socket writeData: benData withTimeout: timeout tag: _tagCounter];
    [self.socket writeData: [GCDAsyncSocket LFData] withTimeout: timeout tag:_tagCounter];
    [_blocksByTag setObject: [block copy] forKey: @(_tagCounter)];
    [_buffersByTag setObject: buffer forKey:@(_tagCounter)];
    
    [self.socket readDataWithTimeout: timeout tag: _tagCounter];
    //[self.socket readDataToData: [GCDAsyncSocket CRLFData] withTimeout: timeout buffer: buffer bufferOffset: 0 tag: _tagCounter];
    
    _tagCounter += 1;
    return _tagCounter-1;
}

- (long) evaluateExpression: (NSString*) expression completionBlock: (void (^)(NSDictionary* result)) block {
    
    NSDictionary* command = @{@"op": @"eval", @"code": expression};
    return [self sendCommandDictionary: command completionBlock: block timeout: 6.0];
}

@end
