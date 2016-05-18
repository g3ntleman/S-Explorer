//
//  SESourceStorage.m
//  S-Explorer
//
//  Created by Dirk Theisen on 05.05.16.
//  Copyright © 2016 Cocoanuts. All rights reserved.
//

#import "SESourceStorage.h"
#import <MPEDN/MPEdn.h>
#import "SESyntaxParser.h"
#import "NSColor+OPExtensions.h"


NSString* SETokenTypeAttributeName = @"TokenType";

@interface SESourceStorage () {
    NSMutableAttributedString *contents;
}
@end

@implementation SESourceStorage

- (id) initWithAttributedString: (NSAttributedString*) attrStr {
    if (self = [super init]) {
        contents = attrStr ? [attrStr mutableCopy] : [[NSMutableAttributedString alloc] init];
    }
    return self;
}

- (id) init {
    if (self = [super init]) {
        contents = [[NSMutableAttributedString alloc] init];
    }
    return self;
}

// The next set of methods are the primitives for attributed and mutable attributed string...

- (NSString*) string {
    return [contents string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRange *)range {
    return [contents attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    NSUInteger origLen = [self length];
    [contents replaceCharactersInRange: range withString: str];
    [self edited: NSTextStorageEditedCharacters range: range changeInLength: [self length] - origLen];
}

- (void)setAttributes:(NSDictionary*) attrs range:(NSRange)range {
    [contents setAttributes: attrs range: range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
}

- (NSUInteger) nextWordFromIndex: (NSUInteger) location forward: (BOOL) isForward {
    
    NSString* source = [self string];
    int flags = NSCaseInsensitiveSearch;
    NSRange range;
    if (isForward) {
        range.location = location+1;
        range.length = source.length-range.location;
        //while ([source characterAtIndex:<#(NSUInteger)#>])

        return [source rangeOfCharacterFromSet: MPEdnNonSymbolChars options: flags range: range].location;
    } else {
        flags |= NSBackwardsSearch;
        range.location = 0;
        range.length = location-1;

        return [source rangeOfCharacterFromSet: MPEdnNonSymbolChars options: flags range: range].location+1;
    }
}

// And now the actual reason for this subclass: to provide code-aware word selection behavior

- (NSRange) doubleClickAtIndex: (NSUInteger) location {
    // Start by calling super to get a proposed range.  This is documented to raise if location >= [self length]
    // or location < 0, so in the code below we can assume that location indicates a valid character position.
    NSRange superRange;
    NSString* source = [self string];
    
    superRange.location = [source rangeOfCharacterFromSet: MPEdnNonSymbolChars
                                                  options: NSCaseInsensitiveSearch | NSBackwardsSearch
                                                    range: NSMakeRange(0, location+1)].location+1;
    if ([source characterAtIndex: superRange.location-1] == ':') {
        superRange.location -= 1;
    }
    
    superRange.length = [source rangeOfCharacterFromSet: MPEdnNonSymbolChars
                                                options: NSCaseInsensitiveSearch
                                                  range: NSMakeRange(location, source.length-location)].location - superRange.location;
    
    return superRange;
}

@end

@implementation NSTextStorage (SE)

- (BOOL) expandRange: (NSRange*) rangePtr toParMatchingPar: (unichar) par {
    
    unichar targetPar = matchingPar(par);
    switch (par) {
        case ']':
        case ')': {
            while ((*rangePtr).location > 0) {
                // Search left:
                (*rangePtr).length += 1;
                (*rangePtr).location -= 1;
                unichar matchingPar = [self.string characterAtIndex: (*rangePtr).location];
                NSColor* color = [self attribute: NSForegroundColorAttributeName atIndex: (*rangePtr).location effectiveRange: NULL];
                if (color != [self.class commentColor] && color != [self.class stringColor]) {
                    if (matchingPar == targetPar) {
                        return YES;
                    }
                    if (matchingPar == par) {
                        NSRange newRange = NSMakeRange((*rangePtr).location, 1);
                        if ([self expandRange: &newRange toParMatchingPar: matchingPar]) {
                            *rangePtr = NSUnionRange(*rangePtr, newRange);
                        } else {
                            return NO;
                        }
                    }
                }
                // Continue search...
            }
            return NO;
        }
        case '[':
        case '(': {
            NSUInteger stringLength = self.string.length;
            while (NSMaxRange(*rangePtr) < stringLength) {
                // Search left:
                (*rangePtr).length += 1;
                unichar matchingPar = [self.string characterAtIndex: NSMaxRange(*rangePtr)-1];
                if (matchingPar == targetPar) {
                    return YES;
                }
                if (matchingPar == par) {
                    NSRange newRange = NSMakeRange(NSMaxRange(*rangePtr)-1, 1);
                    if ([self expandRange: &newRange toParMatchingPar: matchingPar]) {
                        *rangePtr = NSUnionRange(*rangePtr, newRange);
                    } else {
                        return NO;
                    }
                }
                // Continue search...
            }
            return NO;
        }
        default:
            NSLog(@"No paranthesis detected.");
            return NO;
    }
}

- (void) colorizeRange: (NSRange) aRange
               symbols: (NSSet*) sortedSymbols
        defaultSymbols: (NSSet*) defaultSymbols {
    
    [self beginEditing];
    
    [self removeAttribute: NSForegroundColorAttributeName range: aRange];
    [self removeAttribute: SETokenTypeAttributeName range: aRange];
    
    __block int commentLevel = 0; // if >0, the nesting level of the current comment macro
    
    SESyntaxParser* parser =
    [[SESyntaxParser alloc] initWithString: self.string
                                     range: aRange
                                     block: ^(SESyntaxParser *parser, SEParserResult pResult, BOOL *stopRef) {
                                         NSTextStorage* textStorage = self;
                                         
                                         // Check for closing par of comment macro:
                                         if (pResult.occurrence.token == RIGHT_PAR && commentLevel == pResult.depth) {
                                             commentLevel = 0; // end comment
                                         }
                                         
                                         // Treat everything inside the comment macro as a comment:
                                         if (commentLevel) {
                                             pResult.occurrence.token = COMMENT;
                                         }
                                         
                                         switch (pResult.occurrence.token) {
                                             case RIGHT_PAR: {
                                                 if (commentLevel == pResult.depth) {
                                                     commentLevel = 0; // end comment
                                                 }
                                                 break;
                                             }
                                                 
                                             case COMMENT: {
                                                 NSDictionary* commentAttributes = @{NSForegroundColorAttributeName: [self.class commentColor], SETokenTypeAttributeName: @(COMMENT)};
                                                 [textStorage addAttributes: commentAttributes range: pResult.occurrence.range];
                                                 break;
                                             }
                                             case STRING: {
                                                 NSDictionary* stringAttributes = @{NSForegroundColorAttributeName: [self.class stringColor], SETokenTypeAttributeName: @(STRING)};
                                                 [textStorage addAttributes: stringAttributes range: pResult.occurrence.range];
                                                 break;
                                             }
                                             case NUMBER: {
                                                 NSDictionary* constantAttributes = @{NSForegroundColorAttributeName: [self.class numberColor], SETokenTypeAttributeName: @(NUMBER)};
                                                 [textStorage addAttributes: constantAttributes range: pResult.occurrence.range];
                                                 break;
                                             }
                                             case KEYWORD: {
                                                 NSDictionary* constantAttributes = @{NSForegroundColorAttributeName: [self.class keywordColor], SETokenTypeAttributeName: @(KEYWORD)};
                                                 [textStorage addAttributes: constantAttributes range: pResult.occurrence.range];
                                                 break;
                                             }
                                             case CONSTANT: {
                                                 NSDictionary* constantAttributes = @{NSForegroundColorAttributeName: [self.class constantColor], SETokenTypeAttributeName: @(CONSTANT)};
                                                 [textStorage addAttributes: constantAttributes range: pResult.occurrence.range];
                                                 break;
                                             }
                                             case ATOM: {
                                                 
                                                 if (pResult.depth>=1) {
                                                     //NSString* tokenString = [textStorage.string substringWithRange: tokenInstance.occurrence];
                                                     //NSLog(@"Colorizer found word '%@'", tokenString);
                                                     
                                                     NSColor* color = nil;
                                                     NSString* word = [textStorage.string substringWithRange: pResult.occurrence.range];
                                                     
                                                     if (pResult.elementCount == 0 && [word isEqualToString: @"comment"]) {
                                                         commentLevel = pResult.depth;
                                                     }
                                                     
                                                     if ([defaultSymbols containsObject: word]) {
                                                         color = [self.class coreSymbolColor] ; // Mark as "core" function / name
                                                     } else if ([sortedSymbols containsObject: word]) {
                                                         //NSLog(@"Colorizing '%@'", word);
                                                         color = [self.class symbolColor]; // Mark as "custom" function / name
                                                     }

                                                     
                                                     if (color) {
                                                         NSDictionary* keywordAttributes = @{NSForegroundColorAttributeName: color, SETokenTypeAttributeName: @(ATOM)};
                                                         [textStorage addAttributes: keywordAttributes range: pResult.occurrence.range];
                                                     }
                                                 }
                                                 break;
                                             }
                                             default:
                                                 break;
                                         }
                                     }];
    
    
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    [parser parseAll];
    NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
    NSUInteger duration = lround((endTime-startTime)*1000.0);
    if (duration > 10.0) {
        NSLog(@"Parsing & Highlighting %ld chars took %ld milliseconds.", aRange.length, duration);
    }
    [self endEditing];
}


+ (NSColor*) commentColor {
    return [NSColor colorWithDeviceRed:0.0 green:0.6 blue:0.0 alpha:1.0];
}

+ (NSColor*) stringColor {
    return [NSColor redColor];
}

+ (NSColor*) numberColor {
    return [NSColor purpleColor];
}

+ (NSColor*) keywordColor {
    return [NSColor brownColor];
}

+ (NSColor*) symbolColor {
    return [[NSColor blueColor] blendedColorWithFraction: 0.5 ofColor: [NSColor blackColor]];
}

+ (NSColor*) coreSymbolColor {
    return [[NSColor blueColor] blendedColorWithFraction: 0.5 ofColor: [NSColor lightGrayColor]];
}




+ (NSColor*) constantColor {
    return [NSColor orangeColor];
}

- (void) markCharsAtRange: (NSRange) parRange {
    
    NSColor* markColor = [NSColor colorFromHexRGB: @"F0E609"];
    
    [self beginEditing];
    [self addAttribute: NSBackgroundColorAttributeName value: markColor range: NSMakeRange(parRange.location, 1)];
    [self addAttribute: NSBackgroundColorAttributeName value: markColor range: NSMakeRange(NSMaxRange(parRange)-1, 1)];
    [self endEditing];
}

- (void) unmarkChars {
    [self removeAttribute: NSBackgroundColorAttributeName range: NSMakeRange(0, self.string.length)];
}

- (void) unmarkPar {
    // Remove old par mark, if necessary:
    [self unmarkChars];
}

- (void) markParCorrespondingToParAtIndex: (NSUInteger) index {
    
    if (index >= self.string.length) {
        return;
    }
    
    NSUInteger tokenAtIndex = [[self attribute: SETokenTypeAttributeName atIndex:index effectiveRange:NULL] unsignedIntegerValue];
    
    // Do not mark pars within comments or strings:
    if (tokenAtIndex == STRING || tokenAtIndex == COMMENT) {
        return;
    }
    
    [self unmarkPar];
    
    
    unichar par = [self.string characterAtIndex: index];
    
    if (! isPar(par)) return;
    
    NSRange parRange = NSMakeRange(index, 1);
    BOOL match = [self expandRange: &parRange toParMatchingPar: par];
    
    if (match) {
        [self markCharsAtRange: parRange];
        //NSLog(@"found par match at %@", NSStringFromRange(parRange));
    } else {
        NSLog(@"Should find par matching '%c'", par);
    }
}

@end
