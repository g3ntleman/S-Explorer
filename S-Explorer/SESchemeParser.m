//
//  BRSchemeParser.m
//  S-Explorer
//
//  Created by Dirk Theisen on 11.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SESchemeParser.h"
#include <ctype.h>

@implementation SESchemeParser {
    unichar* characters;
    NSUInteger length;
    NSUInteger position;
    NSRange stringRange;
}

@synthesize delegateBlock;

+ (NSSet*) keywords {
    
    static NSSet* keywords = nil;
    if (! keywords) {
        keywords = [[NSSet alloc] initWithArray: @[@"else", @"=>", @"define", @"unquote", @"unquote-splicing", @"quote", @"lambda", @"if", @"set!", @"begin", @"cond", @"and", @"or", @"not", @"case", @"let", @"let*", @"letrec", @"do", @"delay", @"quasiquote", @"import", @"null?", @"list", @"sort", @"len", @"cdr", @"car", @"filter", @"equal?", @"map", @"string-length", @"vector-ref", @"clojure?", @"number?", @"string?", @"<", @">", @"+", @"-", @"*", @"/"]];
    }
    return keywords;
}

- (id) initWithString: (NSString*) schemeSource
                range: (NSRange) range
                block: (SESchemeParserBlock) aDelegateBlock {
    
    if (! schemeSource.length) return nil;
    
    NSParameterAssert(NSMaxRange(range) <= schemeSource.length);
    
    if (self = [self init]) {
        delegateBlock = aDelegateBlock;
        _string = schemeSource;
        length = range.length;
        stringRange = range;
        characters = malloc(sizeof(unichar) * length + 1);
        characters[length] = EOF;
        [schemeSource getCharacters: characters range: stringRange];
    }
    return self;
}

- (void) dealloc {
    free(characters);
}

- (unichar) getc {
    if (position >= length-1) return 0;
    return characters[position++];
}

- (unichar) peekc {
    if (position >= length-1) return 0;
    return characters[position];
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
            do c = [self getc]; while (c != '\n' && c != (unichar)EOF);
            result.range.length = position - result.range.location-1;
            return result;
        }
    } while (c && isspace(c));
    
    result.range.location = position-1;

    switch (c) {
        case 0:
            result.token = END_OF_INPUT;
            result.range.length = 0;
            return result;
        case '(':
            result.token = LEFT_PAR;
            result.range.length = 1;
            return result;
        case ')':
            result.token = RIGHT_PAR;
            result.range.length = 1;
            return result;
        case '.':
            result.token = DOT;
            result.range.length = 1;
            return result;
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
            } while (c != 0 && !isspace(c) && c != '(' && c != ')' && c != ';');
                
            if (c) position -= 1;
            result.range.length = position-result.range.location;
            unichar firstChar = characters[result.range.location];
            if (firstChar == '#' || isdigit(firstChar)) {
                result.token = NUMBER;
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

//
///* Read just one more cdr for this s-expression. */
//lisp_object
//read_cdr(FILE *infile)
//{
//    lisp_object cdr;
//    lisp_object token;
//    
//    cdr = lisp_read(infile);
//    token = ratom(infile);
//    
//    if (object_type(token) == RIGHT_PAREN)
//        return(cdr);
//    else return(lisp_error(ILLFORMED_DOTTED_PAIR, cdr));
//}
//
///* Read the remainder of this list. */
//lisp_object
//read_tail(FILE *infile)
//{
//    lisp_object token;
//    lisp_object temp;
//    
//    token = ratom(infile);
//    switch(object_type(token)) {
//        case SYMBOL:
//            return(cons(token, read_tail(infile)));
//        case LEFT_PAREN:
//            /* Make sure the read_head is done first. */
//            temp = read_head(infile);
//            return(cons(temp, read_tail(infile)));
//        case DOT:
//            return(read_cdr(infile));
//        case RIGHT_PAREN:
//            return(nil_object);
//        case END_OF_INPUT:
//            return(lisp_error(EOF_IN_LIST, token));
//    }
//}
//
///* Read a list. */
//lisp_object
//read_head(FILE *infile)
//{
//    lisp_object token;
//    lisp_object temp;
//    
//    token = ratom(infile);
//    switch(object_type(token)) {
//        case SYMBOL:
//            return(cons(token, read_tail(infile)));
//        case LEFT_PAREN:
//            /* Make sure the read_head is done first. */
//            temp = read_head(infile);
//            return(cons(temp, read_tail(infile)));
//        case RIGHT_PAREN:
//            return(nil_object);
//        case DOT:
//            return(lisp_error(ILLFORMED_DOTTED_PAIR, token));
//        case END_OF_INPUT:
//            return(lisp_error(EOF_IN_LIST, token));
//    }
//}
//
///* Read in and return one s-expression. Return the token (not the symbol)
// end_of_input_token on EOF. */
//lisp_object
//lisp_read(FILE *infile)
//{
//    lisp_object token;
//    
//    token = ratom(infile);
//    switch(object_type(token)) {
//        case SYMBOL:
//            return(token);
//        case LEFT_PAREN:
//            return(read_head(infile));
//        case RIGHT_PAREN:
//            return(lisp_error(TOO_MANY_RIGHT_PARENS, token));
//        case DOT:
//            return(lisp_error(ILLFORMED_DOTTED_PAIR, token));
//        case END_OF_INPUT:
//            return(end_of_input_token);
//    }
//}
//
//lisp_object
//load(lisp_object filename)
//{
//    if (!is_symbol(filename))
//        return(lisp_error(BAD_FILE_SPEC, filename));
//    else {
//        FILE *infile;
//        
//        infile = fopen(filename->fields.symbol_field.symbol_name, "r");
//        if (infile == NULL)
//            return(lisp_error(FILE_OPEN_FAILURE, filename));
//        else {
//            lisp_object obj;
//            
//            while ((obj = lisp_read(infile)) != end_of_input_token) {
//                lisp_print(eval(obj, THE_EMPTY_ENVIRONMENT), stdout);
//                putchar('\n');
//            }
//            return(t_object);
//        }
//    }
//}
//
//lisp_object
//read_from_stdin(void)
//{
//    return(lisp_read(stdin));
//}

@end
