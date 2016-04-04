//
//  BRSchemeParser.h
//  S-Explorer
//
//  Created by Dirk Theisen on 11.06.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
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
    NUMBER,
    CONSTANT,
    KEYWORD
} s_token;


typedef struct  {
    s_token token;
    NSRange range;
} SETokenOccurrence;

typedef struct  {
    SETokenOccurrence occurrence;
    short depth;
    NSUInteger elementCount;
} SEParserResult;



@class SESyntaxParser;

typedef void (^SESyntaxParserBlock)(SESyntaxParser *parser, SEParserResult result, BOOL* stopRef);

@interface SESyntaxParser : NSObject

@property (strong, nonatomic) SESyntaxParserBlock delegateBlock;
@property (strong, readonly) NSString* string;

- (id) initWithString: (NSString*) sSource
                range: (NSRange) range
                block: (SESyntaxParserBlock) aDelegateBlock;

- (void) parseAll;

@end

extern BOOL isOpeningPar(unichar aChar);
extern BOOL isClosingPar(unichar aChar);
extern unichar matchingPar(unichar aPar);
extern BOOL isPar(unichar aChar);

