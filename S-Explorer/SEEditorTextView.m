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
            while (resultRange.location && ([wordCharSet characterIsMember: [text characterAtIndex: resultRange.location-1]])) {
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
    
    
    // NSLog(@"Validating Item '%@'", NSStringFromSelector(item.action));
    if ([item action] == @selector(contractSelection:)) {
        return self.selectionStack.count > 0;
    }
    if ([self.delegate respondsToSelector: item.action]) {
        return YES;
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
    if ([self.delegate respondsToSelector: _cmd]) {
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


/**
 * Make sure, all actions can also be implemented by the delegate.
 */
- (void) doCommandBySelector: (SEL) aSelector {
    if ([self.delegate respondsToSelector: aSelector]) {
        [self.delegate performSelector: aSelector withObject: self];
        return;
    }
    return [super doCommandBySelector: aSelector];
}


- (IBAction) selectSpecificLine: (id) sender {
    
    
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


+ (NSColor*) commentColor {
    return [NSColor colorWithDeviceRed:0.0 green:0.6 blue:0.0 alpha:1.0];
}

+ (NSColor*) stringColor {
    return [NSColor redColor];
}

+ (NSColor*) numberColor {
    return [NSColor redColor];
}


- (void) parser: (SESchemeParser*) parser
     foundToken: (TokenOccurrence) tokenInstance
        atDepth: (NSInteger) depth
   elementCount: (NSUInteger) elementCount {
    
    NSTextStorage* textStorage = self.textStorage;
    
    switch (tokenInstance.token) {
        case COMMENT: {
            NSDictionary* commentAttributes = @{NSForegroundColorAttributeName: [SEEditorTextView commentColor]};
            [textStorage addAttributes: commentAttributes range: tokenInstance.occurrence];
            break;
        }
        case STRING: {
            NSDictionary* stringAttributes = @{NSForegroundColorAttributeName: [SEEditorTextView stringColor]};
            [textStorage addAttributes: stringAttributes range: tokenInstance.occurrence];
            break;
        }
        case NUMBER: {
            NSDictionary* constantAttributes = @{NSForegroundColorAttributeName: [SEEditorTextView numberColor]};
            [textStorage addAttributes: constantAttributes range: tokenInstance.occurrence];
            break;
        }
        case ATOM: {
            
            if (depth>=1) {
                //NSString* tokenString = [textStorage.string substringWithRange: tokenInstance.occurrence];
                //NSLog(@"Colorizer found word '%@'", tokenString);
                
                if (elementCount == 0) {
                    // Found first list element
                    NSColor* color = nil;
                    NSString* word = [textStorage.string substringWithRange: tokenInstance.occurrence];
                    
                    //NSLog(@"Colorizer found word '%@'", word);
                    if ([[SESchemeParser keywords] containsObject: word]) {
                        color = [NSColor purpleColor];
                    } else if ([parser.keywords containsObject: word]) {
                        color = [NSColor blueColor];
                    }
                    
                    if (color) {
                        NSDictionary* keywordAttributes = @{NSForegroundColorAttributeName: color};
                        [textStorage addAttributes: keywordAttributes range: tokenInstance.occurrence];
                    }
                }
            }
            break;
        }
        default:
            break;
    }
}


@end
