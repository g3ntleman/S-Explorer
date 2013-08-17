//
//  BRSchemeParser.h
//  Bracket
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
    STRING
} scheme_token;


typedef struct  {
    scheme_token token;
    NSRange occurrence;
    unsigned short depth;
} TokenOccurrence;


@class SESchemeParser;

@protocol SESchemeParserDelegate <NSObject>

- (void) parser: (SESchemeParser*) parser
     foundToken: (TokenOccurrence) tokenInstance
        atDepth: (NSInteger) depth
   elementCount: (NSUInteger) elementCount;

@end

@interface SESchemeParser : NSObject

@property (strong) id <SESchemeParserDelegate> delegate;
@property (strong, readonly) NSString* string;

+ (NSSet*) keywords;

- (id) initWithString: (NSString*) schemeSource;
- (void) parse;

@end
