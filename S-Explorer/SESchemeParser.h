//
//  BRSchemeParser.h
//  S-Explorer
//
//  Created by Dirk Theisen on 11.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    /* tokens */
    DOT,
    LEFT_PAR,
    RIGHT_PAR,
    END_OF_INPUT,
    ATOM,
    COMMENT,
    STRING,
    NUMBER
} scheme_token;


typedef struct  {
    scheme_token token;
    NSRange range;
} SETokenOccurrence;

typedef struct  {
    SETokenOccurrence occurrence;
    short depth;
    NSUInteger elementCount;
} SEParserResult;



@class SESchemeParser;

typedef void (^SESchemeParserBlock)(SESchemeParser *parser, SEParserResult result, BOOL* stopRef);


//@protocol SESchemeParserDelegate <NSObject>
//
//- (void) parser: (SESchemeParser*) parser
//     foundToken: (TokenOccurrence) tokenInstance
//        atDepth: (NSInteger) depth
//   elementCount: (NSUInteger) elementCount;
//
//@end

@interface SESchemeParser : NSObject

@property (strong, nonatomic) SESchemeParserBlock delegateBlock;
@property (strong, nonatomic) NSSet* keywords;
@property (strong, readonly) NSString* string;

+ (NSSet*) keywords;

- (id) initWithString: (NSString*) schemeSource
                range: (NSRange) range
                block: (SESchemeParserBlock) aDelegateBlock;

- (void) parseAll;

@end
