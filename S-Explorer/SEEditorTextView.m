//
//  SEEditorTextView.m
//  S-Explorer
//
//  Created by Dirk Theisen on 20.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEEditorTextView.h"

@implementation SEEditorTextView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

static NSCharacterSet* SEWordCharacters() {
    static NSCharacterSet* SEWordCharacters = nil;
    if (! SEWordCharacters) {
        NSMutableCharacterSet* c = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [c addCharactersInString: @"-_!*"];
        SEWordCharacters = [c copy];
    }
    return SEWordCharacters;
}


- (NSRange) selectionRangeForProposedRange: (NSRange) proposedSelRange
                               granularity: (NSSelectionGranularity)granularity {
    if (granularity == NSSelectByWord) {
        NSString* text = self.textStorage.string;
        NSCharacterSet* wordCharSet = SEWordCharacters();
        NSRange resultRange = proposedSelRange;
        if ([wordCharSet characterIsMember: [text characterAtIndex: resultRange.location]]) {
            // Search backward:
            while (([wordCharSet characterIsMember: [text characterAtIndex: resultRange.location-1]])) {
                resultRange.location -= 1;
                resultRange.length += 1;
            }
            // Search forward:
            while (([wordCharSet characterIsMember: [text characterAtIndex: NSMaxRange(resultRange)]])) {
                resultRange.length += 1;
            }
            
            NSLog(@"proposed: %@, result: %@", NSStringFromRange(proposedSelRange), NSStringFromRange(resultRange));
            return resultRange;
        }
    }
    return [super selectionRangeForProposedRange: proposedSelRange granularity:granularity];
}


@end
