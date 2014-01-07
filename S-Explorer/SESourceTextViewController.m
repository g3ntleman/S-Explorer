//
//  SESourceTextViewController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 07.01.14.
//  Copyright (c) 2014 Cocoanuts. All rights reserved.
//

#import "SESourceTextViewController.h"
#import "SESourceEditorTextView.h"

@implementation SESourceTextViewController

- (void) setTextView:(SESourceEditorTextView *)textView {
    _textView = textView;
    _textView.delegate = self;
}


- (IBAction) expandSelection: (id) sender {
    
    NSRange oldRange = self.textView.selectedRange;
    NSRange newRange = oldRange;
    
    NSString* text = self.textView.textStorage.string;
    
    // Check, if expansion is possible at all:
    if (oldRange.location < 1 || NSMaxRange(oldRange) >= text.length) {
        NSBeep();
        return;
    }
    
    unichar leftChar = [text characterAtIndex: oldRange.location-1];
    unichar rightChar = [text characterAtIndex: NSMaxRange(oldRange)];
    if (rightChar == matchingPar(leftChar)) {
        // Extend to pars:
        newRange.location -= 1;
        newRange.length += 2;
    } else {
        [self expandRange: &newRange toParMatchingPar: ')'];
        [self expandRange: &newRange toParMatchingPar: '('];
        // Exclude pars:
        if (newRange.length >= 2) {
            newRange.location += 1;
            newRange.length -= 2;
        }
    }
    
    
    NSLog(@"Expanding selection from %@ to %@", NSStringFromRange(oldRange), NSStringFromRange(newRange));
    
    self.textView.selectedRange = newRange;
}

- (BOOL) textView: (NSTextView*) textView shouldChangeTextInRange: (NSRange) affectedCharRange replacementString: (NSString*) replacementString {
    
    [self unmarkPar];
    
    return YES;
}

- (NSRange) textView: (NSTextView*) textView willChangeSelectionFromCharacterRange: (NSRange) oldRange toCharacterRange: (NSRange) newRange {
    
    [self unmarkPar];
    if (newRange.length == 1) {
        // Check, if user selected one par:
        NSTextStorage* textStorage = self.textView.textStorage;
        unichar theChar = [textStorage.string characterAtIndex: newRange.location];
        
        if (isPar(theChar)) {
            NSRange parRange = NSMakeRange(newRange.location, 1);
            BOOL match = [self expandRange: &parRange toParMatchingPar: theChar];
            
            if (match) {
                return parRange;
            }
        }
    } else if (newRange.length+oldRange.length == 0 && (newRange.location+1 == oldRange.location || newRange.location == oldRange.location+1)) {
        //NSLog(@"Cursor moved one char.");
        
        [self markParCorrespondingToParAtIndex: MIN(oldRange.location, newRange.location)];
    }
    
    return newRange;
}

- (BOOL) expandRange: (NSRange*) rangePtr toParMatchingPar: (unichar) par {
    
    NSTextStorage* textStorage = self.textView.textStorage;
    unichar targetPar = matchingPar(par);
    switch (par) {
        case ']':
        case ')': {
            while ((*rangePtr).location > 0) {
                // Search left:
                (*rangePtr).length += 1;
                (*rangePtr).location -= 1;
                unichar matchingPar = [textStorage.string characterAtIndex: (*rangePtr).location];
                NSColor* color = [textStorage attribute: NSForegroundColorAttributeName atIndex: (*rangePtr).location effectiveRange: NULL];
                if (color != [SESourceEditorTextView commentColor] && color != [SESourceEditorTextView stringColor]) {
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
            NSUInteger stringLength = textStorage.string.length;
            while (NSMaxRange(*rangePtr) < stringLength) {
                // Search left:
                (*rangePtr).length += 1;
                unichar matchingPar = [textStorage.string characterAtIndex: NSMaxRange(*rangePtr)-1];
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

- (void) markParCorrespondingToParAtIndex: (NSUInteger) index {
    
    NSTextStorage* textStorage = self.textView.textStorage;
    
    if (index >= textStorage.string.length) {
        return;
    }
    
    NSColor* colorAtIndex = [textStorage attribute: NSForegroundColorAttributeName atIndex:index effectiveRange:NULL];
    
    // Do not mark pars within comments or strings:
    if (colorAtIndex == [SESourceEditorTextView stringColor] || colorAtIndex == [SESourceEditorTextView commentColor]) {
        return;
    }
    
    [self unmarkPar];
    
    
    unichar par = [textStorage.string characterAtIndex: index];
    
    if (! isPar(par)) return;
    
    NSRange parRange = NSMakeRange(index, 1);
    BOOL match = [self expandRange: &parRange toParMatchingPar: par];
    
    if (match) {
        [textStorage markCharsAtRange: parRange];
        parMarkerSet = YES;
        //NSLog(@"found par match at %@", NSStringFromRange(parRange));
    } else {
        NSLog(@"Should find par matching '%c'", par);
    }
}

- (void) unmarkPar {
    // Remove old par mark, if necessary:
    if (parMarkerSet) {
        [self.textView.textStorage unmarkChars];
        parMarkerSet = NO;
    }
}

@end
