//
//  SEnREPLConnection_Tests.m
//  S-Explorer
//
//  Created by Dirk Theisen on 06.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEnREPLConnection.h"

@interface SEnREPLConnection_Tests : XCTestCase

@end

@implementation SEnREPLConnection_Tests

- (void) setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testSimpleCommand {
    
    NSDictionary* command = @{@"op": @"eval", @"code": @"(map inc (list 1 2 3))"};
    NSError* error = nil;
    SEnREPLConnection* connection = [[SEnREPLConnection alloc] initWithHostname: @"localhost" port: 53209];
    __block NSDictionary* response = nil;
    if (! [connection openWithError: &error]) {
        NSLog(@"Unable to open connection %@", error);
    }
    
    // Wait until connection is established:
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
    
    [connection sendCommandDictionary: command completionBlock:^(NSDictionary* result) {
        response = result;
    }];
    // Wait for result:
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
    XCTAssert(response.count > 0, @"Error: nil response from command %@", command);
    XCTAssertEqualObjects(@"(2 3 4)", response[@"value"], @"Unexpected evaluation result.");
}

@end
