//
//  BRSchemeParser.m
//  S-Explorer
//
//  Created by Dirk Theisen on 11.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SESyntaxParser.h"
#include <ctype.h>

@implementation SESyntaxParser {
    unichar* characters;
    NSUInteger length;
    NSUInteger position;
    NSRange stringRange;
}

@synthesize delegateBlock;

- (id) initWithString: (NSString*) sSource
                range: (NSRange) range
                block: (SESyntaxParserBlock) aDelegateBlock {
    
    if (! sSource.length) return nil;
    
    NSParameterAssert(NSMaxRange(range) <= sSource.length);
    
    if (self = [self init]) {
        delegateBlock = aDelegateBlock;
        _string = sSource;
        length = range.length;
        stringRange = range;
        characters = malloc(sizeof(unichar) * length + 1);
        characters[length] = EOF;
        [sSource getCharacters: characters range: stringRange];
    }
    return self;
}

- (void) dealloc {
    free(characters);
}

- (unichar) getc {
    if (position >= length) return 0;
    return characters[position++];
}

- (unichar) peekc {
    if (position+1 >= length) return 0;
    return characters[position+1];
}

/*_________________Input Routines_________________*/


/* This is the lisp tokenizer; it returns a symbol, or one of `(', `)', `.', or EOF */
- (SETokenOccurrence) nextToken {
    unichar c;

    SETokenOccurrence result;
    
    do {
        c = [self getc];
        if (c == ';') {
            // parse line comment:
            result.token = COMMENT;
            result.range.location = position-1;
            do c = [self getc]; while (c != '\n' && c);
            result.range.length = position - result.range.location;
            return result;
        }
    } while (c && isspace(c));
    
    result.range.location = position-1;

    switch (c) {
        case 0: {
            result.token = END_OF_INPUT;
            result.range.length = 0;
            return result;
        }
        case '(':
        case '[': {
            result.token = LEFT_PAR;
            result.range.length = 1;
            return result;
        }
        case ')':
        case ']': {
            result.token = RIGHT_PAR;
            result.range.length = 1;
            return result;
        }
        case '.': {
            result.token = DOT;
            result.range.length = 1;
            return result;
        }
        case '"':
        result.token = STRING;
        do {
            c = [self getc];
        } while (c != 0 && c != '"');
        result.range.length = position-result.range.location;
        
        return result;
        
        default:
        
        do {
            c = [self getc];
        } while (c && !isspace(c) && c != ';' && ! isPar(c));
        
        if (c) position -= 1;
        result.range.length = position-result.range.location;
        unichar firstChar = characters[result.range.location];
        if (firstChar == '#') {
            result.token = CONSTANT;
        } else if (isdigit(firstChar)) {
            result.token = NUMBER;
        } else if (firstChar == ':') {
            result.token = KEYWORD;
        } else {
            result.token = ATOM;
        }
        return result;
    }
}

- (void) parseAll {
    
    position = 0;
    SEParserResult pResult;
    pResult.depth = 0;
    pResult.elementCount = 0;
    BOOL stop = NO;
    
    while (! stop && (pResult.occurrence = [self nextToken]).token != END_OF_INPUT) {
        //NSLog(@"Found Token '%@'(%d) at %@", [schemeString substringWithRange:tokenInstance.occurrence], tokenInstance.token, NSStringFromRange(tokenInstance.occurrence));
        
        // Adjust offset from -init:
        pResult.occurrence.range.location += stringRange.location;
        
        switch (pResult.occurrence.token) {
            case LEFT_PAR:
                pResult.depth += 1;
                pResult.elementCount = 0;
                delegateBlock(self, pResult, &stop);
                break;
            case RIGHT_PAR:
                pResult.elementCount = 0;
                delegateBlock(self, pResult, &stop);
                pResult.depth -= 1;
                break;
            case ATOM:
            case NUMBER:
            case STRING:
                delegateBlock(self, pResult, &stop);
                pResult.elementCount += 1;
                break;
            default:
                delegateBlock(self, pResult, &stop);
                break;
        }
    }
}


@end

inline BOOL isOpeningPar(unichar aChar) {
    return aChar == '(' || aChar == '[' || aChar == '{';
}

inline BOOL isClosingPar(unichar aChar) {
    return aChar == ')' || aChar == ']' || aChar == '}';
}


unichar matchingPar(unichar aPar) {
    switch (aPar) {
        case '(': return ')';
        case ')': return '(';
        case '[': return ']';
        case ']': return '[';
        case '{': return '}';
        case '}': return '{';
    }
    return 0;
}

BOOL isPar(unichar aChar) {
    return matchingPar(aChar) != 0;
}
