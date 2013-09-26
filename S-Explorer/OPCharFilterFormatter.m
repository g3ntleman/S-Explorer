//
//  OPCharFilterFormatter.m for direct use in IB.
//
//  Created by Dirk Theisen on Mon Mar 24 2003.
//  Copyright (c) 2003 Objectpark Development. All rights reserved.
//

#import "OPCharFilterFormatter.h"

static NSString *nilGuard(NSString *str)
{
    return str ? str : @"";
}

@implementation OPCharFilterFormatter

/*" Removes blanks at the start and beginning. Default implementation returns YES.
Not implemented yet. "*/
+ (BOOL) stripSurroundingSpaces
{
    return YES;
}

+ (NSCharacterSet*) invalidCharacterSet
/*" Returns a set of illegal characters. Those characters are stripped from the input to the corresponding text field. Defaults to the newline character set. Subclass and overwrite to change. "*/ {
    static NSCharacterSet* invalidCharacterSet = nil;

    if (!invalidCharacterSet) {
        invalidCharacterSet = [NSCharacterSet characterSetWithCharactersInString: @"\n\r"];
    }
    return invalidCharacterSet;
}

- (NSString*) stringForObjectValue: (id) obj {
    return [obj description];
}

- (NSAttributedString*) attributedStringForObjectValue: (id) obj
                                 withDefaultAttributes: (NSDictionary*) attrs {
    return [[NSAttributedString alloc] initWithString: nilGuard([self stringForObjectValue: obj])
                                            attributes: attrs];
}

- (BOOL) getObjectValue: (id*) obj
              forString: (NSString*) string
       errorDescription: (NSString**) error {
    *obj = string;
    return YES;
}

- (BOOL) isPartialStringValid: (NSString**) partialStringPtr
        proposedSelectedRange: (NSRangePointer) proposedSelRangePtr
               originalString: (NSString*) origString
        originalSelectedRange: (NSRange) origSelRange
             errorDescription: (NSString**) error {
    NSMutableString* result = nil;
    NSRange illegalRange;
	NSCharacterSet* illegalCharSet = [[self class] invalidCharacterSet];
	
    while ((illegalRange = [*partialStringPtr rangeOfCharacterFromSet: illegalCharSet]).length) {
        if (!result) {
            result = [*partialStringPtr mutableCopy];
            *partialStringPtr = result;
        }
		NSString* upperVariant = [[*partialStringPtr substringWithRange: illegalRange] uppercaseString];
		if ([upperVariant rangeOfCharacterFromSet: illegalCharSet].length == 0) {
			// uppercase variant does not contain illegals, so replace....
			[result replaceCharactersInRange: illegalRange withString: upperVariant];
		} else {
			if ((*proposedSelRangePtr).location>=illegalRange.location) {
				(*proposedSelRangePtr).location-=illegalRange.length;
			}
			[result deleteCharactersInRange: illegalRange];
		}
    }
    // Return YES, if no result string was needed:
    return result==nil;
}


@end

@implementation OPDigitFormatter

+ (NSCharacterSet*) invalidCharacterSet
/*" Returns a set of illegal characters. Those characters are stripped from the input to the corresponding text field. Defaults to the newline character set. Subclass and overwrite to change. "*/ {
    static NSCharacterSet* invalidCharacterSet = nil;
    
    if (!invalidCharacterSet) {
        invalidCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    }
    return invalidCharacterSet;
}


@end

