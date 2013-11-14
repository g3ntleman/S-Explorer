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

static NSInteger globalPort = 50555;

// problem: beim disconnect, connect zyklus, während die REPL noch startet, geht das darauffolgende Kommando verloren.


@implementation SEnREPLConnection_Tests

- (void) setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSDictionary* settings = @{@"RuntimeTool": @"/usr/local/bin/lein",
                               @"RuntimeArguments": @[@"repl", @":headless", @":port"],
                               @"WorkingDirectory": [[NSBundle bundleForClass: [self class]] bundlePath]};
    
    globalPort += 1;
    
    _repl = [[SEREPL alloc] initWithSettings: settings];
    
    [_repl startOnPort: globalPort];
        
    NSError* error = nil;
    self.connection = [[SEnREPLConnection alloc] initWithHostname: @"localhost" port: self.repl.port];
    
    if (! [self.connection openWithError: &error]) {
        NSLog(@"Unable to open connection %@", error);
        
        if (! self.repl.task.isRunning) {
            XCTAssertEqual(self.repl.task.terminationStatus, 0, @"REPL task exited with error.");
        }
    }
    
    // Wait until connection is established:
    
    while (! self.connection.socket.isConnected && ! self.connection.socket.isDisconnected) {
        NSLog(@"Waiting for client socket to connect...");
        [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
//        if (self.repl.port != self.connection.port) {
//            [self.connection close];
//            [self.connection openWithError: &error];
//        }
    }
    
}


- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    [self.connection close];
    [self.repl stop];
    // Wait for the task to actually terminate, so we can restart it:
    if (self.repl.task.isRunning) {
        NSLog(@"Waiting for JVM to terminate.");
        while (self.repl.task.isRunning) {
            sleep(0.1);
        }
        _repl = nil;
    }
}




- (void) testMultipleExpressionEvaluations {
    
    NSString* testExpression = @"(map inc (list 1 2 3))";
    __block NSString* evaluationResult = nil;

    [self.connection evaluateExpression: testExpression completionBlock:^(SEnREPLEvaluationState *evalState) {
        XCTAssert(evalState.results.count > 0, @"Error: nil response evaluating '%@'.", testExpression);
        evaluationResult = [evalState.results firstObject];
        XCTAssertEqualObjects(@"(2 3 4)", evaluationResult, @"Unexpected evaluation result.");
    }];
    // Wait for result:
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
    XCTAssert(evaluationResult.length > 0, @"-evaluateExpression:... returned no result in time.");
    
    // Second evaluation on same connection:
    
    NSString* testExpressionLF = @"(map inc (list 3 4 5))";
    __block NSString* evaluationResultLF = nil;

    [self.connection evaluateExpression: testExpressionLF completionBlock: ^(SEnREPLEvaluationState *evalState) {
        XCTAssert(evalState.results.count > 0, @"Error: nil response evaluating '%@'.", testExpressionLF);
        evaluationResultLF = [evalState.results firstObject];
        XCTAssertEqualObjects(@"(4 5 6)", evaluationResultLF, @"Unexpected evaluation result.");
    }];
    // Wait for result:
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.5]];
    XCTAssert(evaluationResultLF.length > 0, @"-evaluateExpression:... returned no result.");
}


- (void) testLongResultExpressionEvaluation {
    
    NSString* testExpression = @"(range 3000)";
    __block NSString* evaluationResult = nil;
    [self.connection evaluateExpression: testExpression completionBlock: ^(SEnREPLEvaluationState *evalState) {
        XCTAssert(evalState.results.count > 0, @"Error: nil response evaluating '%@'.", testExpression);
        evaluationResult = [evalState.results firstObject];
        XCTAssert(evaluationResult.length >= 0, @"-evaluateExpression:... returned no result.");
    }];
    // Wait for result:
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.5]];
    XCTAssert([evaluationResult hasSuffix: @" 2999)"], @"-evaluateExpression:... returned wrong result.");
    //NSLog(@"testLongResultExpressionEvaluation returned %@", evaluationResults);
}


@end
