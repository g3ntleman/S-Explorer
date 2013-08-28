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

@property (strong, nonatomic) id <SESchemeParserDelegate> delegate;
@property (strong, nonatomic) NSSet* keywords;
@property (strong, readonly) NSString* string;

+ (NSSet*) keywords;

- (id) initWithString: (NSString*) schemeSource
                range: (NSRange) range
             delegate: (id) delegate;

- (void) parseAll;

@end
