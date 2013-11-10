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

@property (strong, nonatomic) NSMutableData* readBuffer;
@property (strong, nonatomic) NSMutableDictionary* blockOperationsByTag;

@end

@implementation SEnREPLConnection

- (id) initWithHostname: (NSString*) hostname port: (NSInteger) port {
    if (self = [self init]) {
        _hostname = [hostname copy];
        _port = port;
        _readBuffer = [[NSMutableData alloc] initWithCapacity: 1000];
        _blockOperationsByTag = [[NSMutableDictionary alloc] initWithCapacity: 4];
        _socket = [[GCDAsyncSocket alloc] initWithDelegate: self delegateQueue: dispatch_get_main_queue()];
        _socket.delegate = self;
    }
    return self;
}

- (void) dealloc {
    [self close];
}

- (BOOL) openWithError: (NSError**) errorPtr {
    NSAssert([self.socket isDisconnected], @"Socket not set and diconnected.");
    return [self.socket connectToHost: self.hostname onPort: self.port error: errorPtr];
}

- (void) close {
    if ([_socket isConnected]) {
        [_socket disconnect];
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

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Connected to %@.", host);
}

//- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
//    NSLog(@"Socket read %lu bytes.", (unsigned long)partialLength);
//}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"Socket read %@.", data);
    SEnREplResultBlock block = [_blockOperationsByTag objectForKey: @(tag)];
    
    NSDictionary* result = (id)[OPBEncoder objectFromEncodedData: data];
    
    block(result);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"Socket wrote data for tag %ld.", (long)tag);
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    NSLog(@"Socket (%@) error: %@.", sock, error);

}

/**
 * Sends the encoded commandDictionary to the nREPL server process. 
 * Calls the given block after decoding the result.
 * Returns the tag of the command.
 **/
- (long) sendCommandDictionary: (NSDictionary*) commandDictionary completionBlock: (void (^)(NSDictionary* result)) block {
    
    NSAssert([self.socket isConnected], @"Cannot send Command without open connection. -open first.");
 
    NSData* benData = [[[OPBEncoder alloc] initForEncoding] encodeRootObject: commandDictionary];
    NSString* benString = [[NSString alloc] initWithData: benData encoding:NSUTF8StringEncoding];
    NSLog(@"Sending '%@'", benString);
    [self.socket writeData: benData withTimeout: 20.0 tag: _tagCounter];
    [self.socket writeData: [GCDAsyncSocket LFData] withTimeout:20.0 tag:_tagCounter];
    [_blockOperationsByTag setObject: [block copy] forKey: @(_tagCounter)];
    [self.socket readDataWithTimeout:15.0 tag:0];
    _tagCounter += 1;
    return _tagCounter-1;
}


@end
