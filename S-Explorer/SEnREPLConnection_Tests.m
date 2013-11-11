//
//  SEnREPLConnection_Tests.m
//  S-Explorer
//
//  Created by Dirk Theisen on 06.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEnREPLConnection.h"
#import "SEREPL.h"

@interface SEnREPLConnection_Tests : XCTestCase

@property SEREPL* repl;
@property SEnREPLConnection* connection;

@end

@implementation SEnREPLConnection_Tests

- (void) setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSDictionary* settings = @{@"RuntimeTool": @"/usr/local/bin/lein",
                               @"RuntimeArguments": @[@"repl", @":headless", @":port", @"50564"],
                               @"WorkingDirectory": [[NSBundle bundleForClass: [self class]] bundlePath]};
    
    _repl = [[SEREPL alloc] initWithSettings: settings];
    
    [_repl start];
    
    NSError* error = nil;
    self.connection = [[SEnREPLConnection alloc] initWithHostname: @"localhost" port: self.repl.port];
    
    if (! [self.connection openWithError: &error]) {
        NSLog(@"Unable to open connection %@", error);
        
        if (! self.repl.task.isRunning) {
            XCTAssertEqual(self.repl.task.terminationStatus, 0, @"REPL task exited with error.");
        }
    }
    
    // Wait until connection is established:
    //[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
    
}

- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    [self.connection close];
    [self.repl stop];
    
}


//- (void) testSimpleExpressionEvaluation {
//    
//    NSString* testExpression = @"(map inc (list 1 2 3))";
//    __block NSString* evaluationResult = nil;
//
//    [self.connection evaluateExpression: testExpression completionBlock: ^(NSDictionary* result) {
//        XCTAssert(result.count > 0, @"Error: nil response evaluating '%@'.", testExpression);
//        evaluationResult = result[@"value"];
//    }];
//    // Wait for result:
//    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
//    XCTAssertNotNil(evaluationResult, @"-evaluateExpression:... returned no result.");
//    XCTAssertEqualObjects(@"(2 3 4)", evaluationResult, @"Unexpected evaluation result.");
//}


- (void) testLongResultExpressionEvaluation {
    
    NSString* testExpression = @"(range 3000)";
    __block NSString* evaluationResult = nil;
    
    [self.connection evaluateExpression: testExpression completionBlock: ^(NSDictionary* result) {
        XCTAssert(result.count > 0, @"Error: nil response evaluating '%@'.", testExpression);
        evaluationResult = result[@"value"];
    }];
    // Wait for result:
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.5]];
    XCTAssertNotNil(evaluationResult, @"-evaluateExpression:... returned no result.");
    NSLog(@"testLongResultExpressionEvaluation returned %@", evaluationResult);
}


@end
