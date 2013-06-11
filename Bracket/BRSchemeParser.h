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
    COMMENT
} scheme_token;


typedef struct  {
    scheme_token token;
    NSRange occurrence;
    unsigned short depth;
} TokenOccurrence;


@class BRSchemeParser;

@protocol BRSchemeParserDelegate <NSObject>

- (void) parser: (BRSchemeParser*) parser
     foundToken: (TokenOccurrence) tokenInstance
        atDepth: (NSInteger) depth
   elementCount: (NSUInteger) elementCount;

@end

@interface BRSchemeParser : NSObject

@property (strong) id <BRSchemeParserDelegate> delegate;

+ (NSSet*) keywords;

- (id) initWithString: (NSString*) schemeSource;
- (void) parse;

@end
