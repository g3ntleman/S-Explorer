//
//  SEEditorController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 16.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEEditorController.h"
#import "NoodleLineNumberView.h"
#import "NSTimer-NoodleExtensions.h"
#import "SEApplicationDelegate.h"
#import "NSColor+OPExtensions.h"

NSSet* SESingleIndentFunctions() {
    static NSSet* SESingleIndentFunctions = nil;
    if (! SESingleIndentFunctions) {
        SESingleIndentFunctions = [NSSet setWithObjects: @"define", @"lambda", @"module", @"let", @"letrec", @"let*", nil];
    }
    return SESingleIndentFunctions;
}


static inline BOOL isOpeningPar(unichar aChar) {
    return aChar == '(' || aChar == '[' || aChar == '{';
}

static inline BOOL isClosingPar(unichar aChar) {
    return aChar == ')' || aChar == ']' || aChar == '}';
}


static unichar matchingPar(unichar aPar) {
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

static BOOL isPar(unichar aChar) {
    return matchingPar(aChar) != 0;
}

@interface  NSMutableAttributedString (SEExtensions)
- (void) markCharsAtRange: (NSRange) parRange;
- (void) unmarkChars;

@end

@implementation NSMutableAttributedString (SEExtensions) 

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


@end




@implementation SEEditorController {
    NSTimer* flashParTimer;
    
}

- (NSColor*) commentColor {
    return [NSColor colorWithDeviceRed:0.0 green:0.6 blue:0.0 alpha:1.0];
}

- (NSColor*) stringColor {
    return [NSColor redColor];
}

- (NSColor*) numberColor {
    return [NSColor redColor];
}


- (void) parser: (SESchemeParser*) parser
     foundToken: (TokenOccurrence) tokenInstance
        atDepth: (NSInteger) depth
   elementCount: (NSUInteger) elementCount {
    
    NSTextStorage* textStorage = self.textEditorView.textStorage;
    
    switch (tokenInstance.token) {
        case COMMENT: {
            NSDictionary* commentAttributes = @{NSForegroundColorAttributeName: self.commentColor};
            [textStorage addAttributes: commentAttributes range: tokenInstance.occurrence];
            break;
        }
        case STRING: {
            NSDictionary* commentAttributes = @{NSForegroundColorAttributeName: self.stringColor};
            [textStorage addAttributes: commentAttributes range: tokenInstance.occurrence];
            break;
        }
        case NUMBER: {
            NSDictionary* commentAttributes = @{NSForegroundColorAttributeName: self.numberColor};
            [textStorage addAttributes: commentAttributes range: tokenInstance.occurrence];
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
                    } else if ([self.keywords containsObject: word]) {
                        color = [NSColor blueColor];
                    }
                    
                    if (color) {
                        NSDictionary* commentAttributes = @{NSForegroundColorAttributeName: color};
                        [textStorage addAttributes: commentAttributes range: tokenInstance.occurrence];
                    }
                }
            }
            break;
        }
        default:
            break;
    }
}

- (void) awakeFromNib {
    
    NSScrollView* scrollView = self.textEditorView.enclosingScrollView;
    if (! scrollView.verticalRulerView) {
        _lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView: scrollView];
        scrollView.verticalRulerView = self.lineNumberView;
        [scrollView setHasHorizontalRuler: NO];
        [scrollView setHasVerticalRuler: YES];
        [scrollView setRulersVisible: YES];
    }
}

- (IBAction) colorize: (id) sender {
    
    NSTextStorage* textStorage = self.textEditorView.textStorage;
    
    NSRange fullRange = NSMakeRange(0, textStorage.string.length);
    [textStorage removeAttribute: NSForegroundColorAttributeName range: fullRange];
    //[textStorage removeAttribute: NSBackgroundColorAttributeName range: fullRange];
    
    SESchemeParser* parser = [[SESchemeParser alloc] initWithString: textStorage.string];
    parser.delegate = self;
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    [parser parse];
    NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
    NSLog(@"Parsing & Highlighting took %lf seconds.", endTime-startTime);
}


- (BOOL) expandRange: (NSRange*) rangePtr toParMatchingPar: (unichar) par {

    NSTextStorage* textStorage = self.textEditorView.textStorage;
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
                if (color != self.commentColor && color != self.stringColor) {
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

- (NSUInteger) columnForLocation: (NSUInteger) location {
    NSString* text = self.textEditorView.textStorage.string;
    NSUInteger column = 0;
    while (location>=column && [text characterAtIndex: location-column] != '\n') {
        column += 1;
    }
    return column;
}

- (NSUInteger) indentationAtLocation: (NSUInteger) lineStart {
    NSString* text = self.textEditorView.textStorage.string;
    NSUInteger location = lineStart;
    NSUInteger length = text.length;
    unichar locationChar;
    do {
        locationChar = [text characterAtIndex: location];
    } while (location++<length && locationChar != '\n' && locationChar == ' ');

    return location-lineStart-1;
}

// These: Der Code läuft versehentlich über die Zeilengrenze hinaus und rückt dabei die nächste Zeile (mit?) ein.
- (void) indentInRange: (NSRange) range {
    
    NSUInteger indentation;
    NSRange previouslySelectedRange = self.textEditorView.selectedRange;
    NSTextStorage* textStorage = self.textEditorView.textStorage;
    NSString* text = textStorage.mutableString;
    NSRange initialRange = range = [text lineRangeForRange: range];
    NSUInteger lineNo = 0;
    
    [textStorage beginEditing];
    
    do {
        lineNo++;
        NSLog(@"Should indent in %@", NSStringFromRange(range));
        //NSLog(@"line is %@", NSStringFromRange(lineRange));
        NSRange currentExpressionRange = NSMakeRange(range.location, 0);
        indentation = 0;
        
        if ([self expandRange: &currentExpressionRange toParMatchingPar: ')']) {
            NSLog(@"Next opening par is %@", NSStringFromRange(currentExpressionRange));
            
            NSUInteger parColumn = [self columnForLocation: currentExpressionRange.location];
            NSLog(@"Parent par is at column %lu", parColumn);
            indentation = parColumn;
            
            // Read beginning of outer expression:
            NSUInteger location = currentExpressionRange.location+1;
            unichar locationChar;
            while (location < text.length) {
                locationChar = [text characterAtIndex: location];
                if (locationChar == ' ' || isPar(locationChar) || locationChar == '\n') {
                    break;
                }
                location += 1;
            }
            NSRange wordRange = NSMakeRange(currentExpressionRange.location+1, location - currentExpressionRange.location-1);
            
            if (wordRange.length) {
                indentation += 1;
                NSString* word = [text substringWithRange: wordRange];
                if (! [SESingleIndentFunctions() containsObject: word]) {
                    indentation += wordRange.length;
                }
            }
        }
        
        // Create an NSString with indentation number of spaces:
        unsigned char indentChars[indentation];
        memset(&indentChars, ' ', indentation);
        NSString* spaces = [[NSString alloc] initWithBytesNoCopy: indentChars
                                                          length: indentation
                                                        encoding: NSASCIIStringEncoding
                                                    freeWhenDone: NO];
        
        // Insert spaces, replacing the old indenting ones:
        NSUInteger previousIndentation = [self indentationAtLocation: range.location];
        //self.textEditorView.selectedRange = NSMakeRange(range.location, previousIndentation);
        [textStorage replaceCharactersInRange: NSMakeRange(range.location, previousIndentation) withString: spaces];
        NSInteger indentationChange = indentation-previousIndentation;
        initialRange.length += indentationChange;
        range.length += indentationChange;
//        if (previouslySelectedRange.length > 0) {
//            previouslySelectedRange.length += indentationChange;
//        }
        
        NSRange lineRange = [text lineRangeForRange: NSMakeRange(range.location, 0)];
        NSLog(@"Next line is %@", NSStringFromRange(lineRange));
        if (range.length > lineRange.length) {
            range.location += lineRange.length;
            range.length -= lineRange.length;
        } else break;
    } while (YES);
    
    [textStorage endEditing];
    
    NSLog(@"Indented %lu lines.", lineNo);
    
    if (previouslySelectedRange.length > 0) {
        self.textEditorView.selectedRange = initialRange;
    } else {
        if (previouslySelectedRange.location > range.location+indentation) {
            self.textEditorView.selectedRange = previouslySelectedRange;
        }
    }
    
}

- (IBAction) insertNewline: (id) sender {
    [self.textEditorView insertNewline: sender];
    [self indentInRange: self.textEditorView.selectedRange];
}

- (IBAction) insertTab: (id) sender {
    NSLog(@"Should indent current selected lines.");
    [self indentInRange: self.textEditorView.selectedRange];
}





- (void) flashParCorrespondingToParAtIndex: (NSUInteger) index {
        
    NSTextStorage* textStorage = self.textEditorView.textStorage;
    
    if (index >= textStorage.string.length) {
        return;
    }
    
    NSColor* colorAtIndex = [textStorage attribute: NSForegroundColorAttributeName atIndex:index effectiveRange:NULL];
    
    // Do not flash within comments or strings:
    if (colorAtIndex == self.stringColor || colorAtIndex == self.commentColor) {
        return;
    }

    
    // Remove old flashing, if necessary:
    if (flashParTimer) {
        [flashParTimer fire];
        flashParTimer = nil;
    }
    
    unichar par = [textStorage.string characterAtIndex: index];
    
    if (! isPar(par)) return;
    
    NSRange flashingParRange = NSMakeRange(index, 1);
    BOOL match = [self expandRange: &flashingParRange toParMatchingPar: par];
    
    if (match) {
        
        [textStorage markCharsAtRange: flashingParRange];
        flashParTimer = [NSTimer timerWithTimeInterval: 1.0 repeats: NO block: ^(NSTimer *timer) {
            [textStorage unmarkChars];
        }];
        [[NSRunLoop currentRunLoop] addTimer: flashParTimer forMode: NSDefaultRunLoopMode];
        
        NSLog(@"found par match at %@", NSStringFromRange(flashingParRange));
    } else {
        NSLog(@"Should find par matching '%c'", par);
    }
}

+ (void) recolorTextNotification: (NSNotification*) notification {
    NSLog(@"recolorTextNotification.");
    [notification.object colorize: nil];
}

- (void) textDidChange: (NSNotification*) notification {
    
    NSLog(@"Editor changed text.");
    NSNotification* textChangedNotification = [NSNotification notificationWithName: @"SETextNeedsRecoloring" object: self];
    [[NSNotificationQueue defaultQueue] enqueueNotification: textChangedNotification
                                                 postingStyle: NSPostWhenIdle
                                                 coalesceMask: NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
                                                     forModes: nil];
}

+ (void) load {
    
    static BOOL loaded = NO;
    if (! loaded) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recolorTextNotification:) name: @"SETextNeedsRecoloring" object: nil];
        
        loaded = YES;
    }
}


void OPRunBlockAfterDelay(NSTimeInterval delay, void (^block)(void)) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*delay),
                   dispatch_get_current_queue(), block);
}


- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
    
    if (flashParTimer) {
        [flashParTimer fire];
        flashParTimer = nil;
    }
    return YES;
}


- (NSRange) textView: (NSTextView*) textView willChangeSelectionFromCharacterRange: (NSRange) oldRange toCharacterRange: (NSRange) newRange {
    
    if (newRange.length == 1) {
        // Check, if user selected one par:
        NSTextStorage* textStorage = self.textEditorView.textStorage;
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
        
        //OPRunBlockAfterDelay(0.0, ^{
        [self flashParCorrespondingToParAtIndex: MIN(oldRange.location, newRange.location)];
        //});
    }

    return newRange;
}


//- (void) textViewDidChangeSelection: (NSNotification*) notification {
//    NSRange newRange = [[[notification.object selectedRanges] lastObject] rangeValue];
//    NSRange oldRange = [[notification.userInfo objectForKey: @"NSOldSelectedCharacterRange"] rangeValue];
//    
//    
//    NSLog(@"Selection changed from %@ to %@", NSStringFromRange(oldRange), NSStringFromRange(newRange));
//}

- (IBAction) expandSelection: (id) sender {
    
    NSRange oldRange = self.textEditorView.selectedRange;
    NSRange newRange = oldRange;

    NSString* text = self.textEditorView.textStorage.string;
    
    // Check, if expanstion is possible at all:
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
    
    self.textEditorView.selectedRange = newRange;
}

@end

