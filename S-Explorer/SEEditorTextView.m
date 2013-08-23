//
//  SEEditorTextView.m
//  S-Explorer
//
//  Created by Dirk Theisen on 20.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEEditorTextView.h"
#import "NoodleLineNumberView.h"

@implementation SEEditorTextView {
    NSMutableArray* selectionStack;
}

- (id)initWithFrame:(NSRect)frame {
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
        [self.delegate performSelector: @selector(expandSelection:) withObject: sender];
        if (! NSEqualRanges(oldSelectionRange, self.selectedRange)) {
            [self.selectionStack addObject: [NSValue valueWithRange: oldSelectionRange]];
        }
    }
}


/**
  * selects the given line number. Must be >=1. Does nothing but beep, if given line number is too high.
  */
 
- (NSRange) selectLineNumber: (NSUInteger) line {
    
    NoodleLineNumberView* lineNumberView = (NoodleLineNumberView*)self.enclosingScrollView.verticalRulerView;
    
    if (line > lineNumberView.numberOfLines) {
        NSBeep();
        return NSMakeRange(0,0);
    }
    
    NSRange lineRange = [lineNumberView rangeOfLine: line];
    self.selectedRange = lineRange;
    return lineRange;
}

- (IBAction) ok: (id) sender {
    [self.gotoPanel orderOut: sender];
}

- (IBAction) selectLine: (id) sender {
    
    
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSAlert *alert = [NSAlert alertWithMessageText: @"Select Line Number …"
                                     defaultButton: @"OK"
                                   alternateButton: @"Cancel"
                                       otherButton: nil
                         informativeTextWithFormat: @""];
    
    NSTextField *lineNumberField = [[NSTextField alloc] initWithFrame: NSMakeRect(0, 0, 50, 22)];
    [lineNumberField setAlignment: NSCenterTextAlignment];
    [lineNumberField setIntegerValue: [ud integerForKey: @"GotoPanelLineNumber"]];
    [alert setAccessoryView: lineNumberField];
    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        [lineNumberField validateEditing];
        NSUInteger line = [lineNumberField integerValue];
        
        NoodleLineNumberView* lineNumberView = (NoodleLineNumberView*)self.enclosingScrollView.verticalRulerView;
        if ([lineNumberView isKindOfClass: [NoodleLineNumberView class]]) {
            
            NSRange lineRange = [self selectLineNumber: line];
            [self scrollRangeToVisible: lineRange];
        }
        
        [ud setInteger: line forKey: @"GotoPanelLineNumber"];
    } 
}


@end
