//
//  SESourceStorage.h
//  S-Explorer
//
//  Created by Dirk Theisen on 05.05.16.
//  Copyright © 2016 Cocoanuts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NSString* SETokenTypeAttributeName;

@interface SESourceStorage : NSTextStorage

- (id) init;
- (id) initWithAttributedString: (NSAttributedString*) attrStr;

@end


@interface NSTextStorage (SE)

- (BOOL) expandRange: (NSRange*) rangePtr toParMatchingPar: (unichar) par;

+ (NSColor*) commentColor;

+ (NSColor*) stringColor;

+ (NSColor*) numberColor;

+ (NSColor*) keywordColor;

+ (NSColor*) constantColor;

- (void) colorizeRange: (NSRange) aRange
               symbols: (NSOrderedSet*) sortedSymbols;

- (void) unmarkPar;
- (void) markParCorrespondingToParAtIndex: (NSUInteger) index;

- (void) markCharsAtRange: (NSRange) parRange;
- (void) unmarkChars;

@end