//
//  SEnREPLConnection_Tests.m
//  S-Explorer
//
//  Created by Dirk Theisen on 06.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEnREPLConnection.h"
#import "SEnREPL.h"

@interface SEnREPLConnection_Tests : XCTestCase

@property SEnREPL* repl;
@property SEnREPLConnection* connection;

@end

// problem: beim disconnect, connect zyklus, während die REPL noch startet, geht das darauffolgende Kommando verloren.


@implementation SEnREPLConnection_Tests

- (void) setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSDictionary* settings = @{@"RuntimeTool": @"/usr/local/bin/lein",
                               @"RuntimeArguments": @[@"repl", @":headless"],
                               @"WorkingDirectory": [[NSBundle bundleForClass: [self class]] bundlePath]};
    
    
    _repl = [[SEnREPL alloc] initWithSettings: settings];
    
    NSError* error = nil;
    __block BOOL started = NO;
    
    [_repl startWithCompletionBlock:^(SEnREPL *repl, NSError *error) {
        started = (error == nil);
    }];
    
    while (! started) {
        [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
    }
    self.connection = [[SEnREPLConnection alloc] initWithHostname: @"localhost"
                                                             port: self.repl.port
                                                        sessionID: nil];
    
    if (! [self.connection openWithError: &error]) {
        NSLog(@"Unable to open connection %@", error);
        
        if (! self.repl.task.isRunning) {
            XCTAssertEqual(self.repl.task.terminationStatus, 0, @"REPL task exited with error.");
        }
    }
    
    // Wait until connection is established:
    if (self.connection.isConnecting) {
        NSLog(@"Waiting for client socket to connect...");
        while (self.connection.isConnecting) {
            [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
        }
        if (self.connection.socket.isConnected) {
            NSLog(@"Connected.");
        }
    }
    XCTAssert(self.connection.socket.isConnected, @"Unable to connect to REPL server on port %ld", (long)self.repl.port);
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

    [self.connection evaluateExpression: testExpression completionBlock:^(SEnREPLResultState *evalState) {
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

    [self.connection evaluateExpression: testExpressionLF completionBlock: ^(SEnREPLResultState *evalState) {
        XCTAssert(evalState.results.count > 0, @"Error: No results evaluating '%@': %@", testExpressionLF, evalState.error);
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
    [self.connection evaluateExpression: testExpression completionBlock: ^(SEnREPLResultState *evalState) {
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
