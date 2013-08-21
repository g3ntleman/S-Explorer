//
//  SEEditorTextView.m
//  S-Explorer
//
//  Created by Dirk Theisen on 20.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEEditorTextView.h"

@implementation SEEditorTextView {
    NSMutableArray* selectionStack;
}

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

/* Change word selection behaviour to include hythens and other characters common in function names. */
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
            
            //NSLog(@"proposed: %@, result: %@", NSStringFromRange(proposedSelRange), NSStringFromRange(resultRange));
            return resultRange;
        }
    }
    return [super selectionRangeForProposedRange: proposedSelRange granularity:granularity];
}

- (NSMutableArray*) selectionStack {
    if (! selectionStack) {
        selectionStack = [[NSMutableArray alloc] initWithCapacity: 10];
    }
    return selectionStack;
}

- (BOOL) validateMenuItem: (NSMenuItem*) item {
    
    if ([item action] == @selector(contractSelection:)) {
        return self.selectionStack.count > 0;
    }
    return [super validateMenuItem: item];
}
- (void) didChangeText {
    [super didChangeText];
    [self.selectionStack removeAllObjects];
}

- (void)moveToEndOfDocumentAndModifySelection: (id) sender {
    // NOP
}

- (void)moveToBeginningOfDocumentAndModifySelection: (id) sender {
    // NOP
}

- (IBAction) contractSelection: (id) sender {
    if (self.selectionStack.count == 0) {
        NSBeep();
        return;
    }
    NSRange oldSelectionRange = [[self.selectionStack lastObject] rangeValue];
    [self.selectionStack removeLastObject];
    self.selectedRange = oldSelectionRange;
}


- (IBAction) expandSelection: (id) sender {
    if ([self.delegate respondsToSelector:_cmd]) {
        NSRange oldSelectionRange = self.selectedRange;
        [self.delegate performSelector: _cmd withObject: sender];
        if (! NSEqualRanges(oldSelectionRange, self.selectedRange)) {
            [self.selectionStack addObject: [NSValue valueWithRange: oldSelectionRange]];
        }
    }
}


@end
