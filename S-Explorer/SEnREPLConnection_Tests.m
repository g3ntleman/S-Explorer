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
#import "XCTestAsync.h"

@interface SEnREPLConnection_Tests : XCTestCase

@property SEnREPL* repl;
@property SEnREPLConnection* connection;

@end

// problem: beim disconnect, connect zyklus, während die REPL noch startet, geht das darauffolgende Kommando verloren.


@implementation SEnREPLConnection_Tests

//- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block NS_AVAILABLE(10_6, 4_0);


- (void) evaluateExpression: (NSString*) expression completionBlock:  (void (^)(SEnREPLConnection* connection, NSDictionary* partialResult)) block {
    
    [self.repl startWithCompletionBlock: ^(SEnREPL* repl, NSError* anError) {
        XCTAssert(anError == nil, @"Error starting REPL: %@", anError);
        
        self.connection = [[SEnREPLConnection alloc] initWithHostname: @"localhost"
                                                                 port: self.repl.port
                                                            sessionID: nil];
        
        [self.connection openWithConnectBlock: ^(SEnREPLConnection* connection, NSError* anError) {
            XCTAssert(anError == nil, @"Error connecting to REPL: %@", anError);

            [self.connection evaluateExpression: expression completionBlock:^(NSDictionary* partialResult) {
                block(self.connection, partialResult);
            }];
        }];
    }];
}


- (void) setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSDictionary* settings = @{@"RuntimeTool": @"/usr/local/bin/lein",
                               @"RuntimeArguments": @[@"repl", @":headless"],
                               @"WorkingDirectory": @"/tmp/"//[[NSBundle bundleForClass: [self class]] bundlePath]};
                               };
    
    
    _repl = [[SEnREPL alloc] initWithSettings: settings];
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
    
    XCAsyncFailAfter(15.0, @"%@ did not finish in time.", NSStringFromSelector(_cmd));
    
    NSString* testExpression = @"(map inc (list 1 2 3))";
    
    [self evaluateExpression: testExpression completionBlock:^(SEnREPLConnection *connection, NSDictionary *partialResult) {
        //XCTAssert(evalState.results.count > 0, @"Error: nil response evaluating '%@'.", testExpression);
        NSString* evaluationResult = partialResult[@"value"];
        XCTAssertEqualObjects(@"(2 3 4)", evaluationResult, @"Unexpected evaluation result.");
        
        // Second evaluation on same connection:
        
        NSString* testExpressionLF = @"(map inc (list 3 4 5))";
        [connection evaluateExpression: testExpressionLF completionBlock: ^(/*SEnREPLResultState *evalState,*/ NSDictionary* partialResult) {
            //XCTAssert(evalState.results.count > 0, @"Error: No results evaluating '%@': %@", testExpressionLF, evalState.error);
            //evaluationResultLF = [evalState.results firstObject];
            NSString* evaluationResultLF = partialResult[@"value"];
            XCTAssertEqualObjects(@"(4 5 6)", evaluationResultLF, @"Unexpected evaluation result.");
            XCAsyncSuccess();
        }];
    }];
}


//- (void) testLongResultExpressionEvaluation {
//
//    NSString* testExpression = @"(range 3000)";
//    __block NSString* evaluationResult = nil;
//    [self.connection evaluateExpression: testExpression completionBlock: ^(SEnREPLResultState *evalState, NSDictionary* partialResult) {
//        XCTAssert(evalState.results.count > 0, @"Error: nil response evaluating '%@'.", testExpression);
//        evaluationResult = [evalState.results firstObject];
//        XCTAssert(evaluationResult.length >= 0, @"-evaluateExpression:... returned no result.");
//    }];
//    // Wait for result:
//    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.5]];
//    XCTAssert([evaluationResult hasSuffix: @" 2999)"], @"-evaluateExpression:... returned wrong result.");
//    //NSLog(@"testLongResultExpressionEvaluation returned %@", evaluationResults);
//}


@end
