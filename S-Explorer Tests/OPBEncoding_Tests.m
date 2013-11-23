//
//  OPBEncoding_Tests.m
//  S-Explorer
//
//  Created by Dirk Theisen on 24.10.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OPBEncoder.h"

@interface OPBEncoding_Tests : XCTestCase {
    OPBEncoder* encoder;
}

@end

@implementation OPBEncoding_Tests

- (void) setUp {
    [super setUp];
    
    encoder = [[OPBEncoder alloc] init];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (id) decodeString: (NSString*) bencodeString {
//    NSData* bencodeData = [bencodeString dataUsingEncoding: NSISOLatin1StringEncoding];
//    return [OPBEncoder objectFromEncodedData: bencodeData withTypeBlock:^OPBEncodedType(NSArray *keyPath) {
//        return OPBEncodedStringType;
//    }];
//}

- (void) recode: (id <OPBencoding>) object {
    XCTAssertEqualObjects(object, [OPBEncoder objectFromEncodedData: [encoder encodeRootObject: object]]);
}

- (void) testStringRecoding {
    [self recode: @"spam"];
}

- (void) testArrayRecoding {
    [self recode: @[@"cologne", @(4711)]];
}

- (void) testDictionaryRecoding {
    [self recode: @{@"cow": @"moo", @"spam": @"eggs", @"cologne": @(4711)}];
}

- (void) testStringEncoding {
    XCTAssertEqualObjects([encoder encodeRootObject: @"spam"], [@"4:spam" dataUsingEncoding: NSUTF8StringEncoding], @"String encoding failed.");
    XCTAssertEqualObjects([encoder encodeRootObject: @""], [@"0:" dataUsingEncoding: NSUTF8StringEncoding], @"Empty string encoding failed.");
}

- (void) testIntegerNumberEncoding {
    XCTAssertEqualObjects([encoder encodeRootObject: @(4711)], [@"i4711e" dataUsingEncoding: NSUTF8StringEncoding], @"Integer Number encoding failed.");
    XCTAssertEqualObjects([encoder encodeRootObject: @(4000000000)], [@"i4000000000e" dataUsingEncoding: NSUTF8StringEncoding], @"Integer Number encoding failed.");
    XCTAssertEqualObjects([encoder encodeRootObject: @(-3)], [@"i-3e" dataUsingEncoding: NSUTF8StringEncoding], @"Integer Number encoding failed.");
}

- (void) testFloatNumberEncoding {
    XCTAssertEqualObjects([encoder encodeRootObject: @(-47.11)], [@"i-47.11e" dataUsingEncoding: NSUTF8StringEncoding], @"Float Number encoding failed.");
}

- (void) testArrayEncoding {
    NSArray* testArray = @[@"spam", @"eggs"];
    XCTAssertEqualObjects([encoder encodeRootObject: testArray], [@"l4:spam4:eggse" dataUsingEncoding: NSUTF8StringEncoding], @"Array encoding failed.");
}


- (void) testDictionaryEncoding {
    NSDictionary* testDictionary = @{@"cow": @"moo", @"spam": @"eggs"};
    XCTAssertEqualObjects([encoder encodeRootObject: testDictionary], [@"d3:cow3:moo4:spam4:eggse" dataUsingEncoding: NSUTF8StringEncoding], @"Array encoding failed.");
    
    //NSDictionary* nREPLQueryDictionary = @{@"op": @"eval", @"code": @"(map inc (list 1 2 3))"};
    //NSLog(@"nREPLDict = '%@'", [[NSString alloc] initWithData: [encoder encodeRootObject: nREPLQueryDictionary] encoding: NSUTF8StringEncoding]);

    //NSDictionary* nREPLResultDictionary = (id)[OPBEncoder objectFromEncodedData: [@"d2:ns4:user7:session36:8de1f329-4ab4-4b4c-9033-79d1c70abf035:value7:(2 3 4)ed7:session36:8de1f329-4ab4-4b4c-9033-79d1c70abf036:statusl4:doneee" dataUsingEncoding:NSUTF8StringEncoding]];
    
    //NSLog(@"nREPL Result = '%@'", nREPLResultDictionary);
}

@end
