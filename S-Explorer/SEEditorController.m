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


@interface  NSMutableAttributedString (SEExtensions)
- (void) invertRange: (NSRange) range;
- (void) invertParsAtRange: (NSRange) parRange;

@end

@implementation NSMutableAttributedString (SEExtensions) 

- (void) invertParsAtRange: (NSRange) parRange {
    
    [self beginEditing];
    [self invertRange: NSMakeRange(parRange.location, 1)];
    [self invertRange: NSMakeRange(NSMaxRange(parRange)-1, 1)];
    [self endEditing];
}

- (void) invertRange: (NSRange) range {
    // Invert range:
    NSDictionary* attrs = [self attributesAtIndex: range.location effectiveRange: NULL];
    NSColor* foregroundColor = attrs[NSForegroundColorAttributeName];
    if (! foregroundColor) foregroundColor = [NSColor blackColor];
    NSColor* backgroundColor = attrs[NSBackgroundColorAttributeName];
    if (! backgroundColor) backgroundColor = [NSColor whiteColor];
    
    NSDictionary* invertedAttrs = @{NSForegroundColorAttributeName: backgroundColor,
                                    NSBackgroundColorAttributeName: foregroundColor};
    
    [self addAttributes: invertedAttrs range: range];
}

@end




@implementation SEEditorController {
    NSTimer* flashParTimer;
    
}

- (NSColor*) commentColor {
    return [NSColor greenColor];
}

- (NSColor*) stringColor {
    return [NSColor redColor];
}

- (NSColor*) numberColor {
    return [NSColor orangeColor];
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
                    
                    NSLog(@"Colorizer found word '%@'", word);
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
        NoodleLineNumberView* lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView: scrollView];
        scrollView.verticalRulerView = lineNumberView;
        [scrollView setHasHorizontalRuler: NO];
        [scrollView setHasVerticalRuler: YES];
        [scrollView setRulersVisible: YES];
    }
}

- (IBAction) colorize: (id) sender {
    
    NSTextStorage* textStorage = self.textEditorView.textStorage;
    
    //    struct sexp_callbacks parserCallbacks;
    //    parserCallbacks.handle_atom = &parser_handle_atom;
    //    parserCallbacks.begin_list = &parser_begin_list;
    //    parserCallbacks.end_list = &parser_end_list;
    //    parserCallbacks.handle_error = &parser_handle_error;
    //
    //    // Parse parserCString calling the callbacks above:
    //    int res = sexp_parse(parserCString, &parserCallbacks, (__bridge void*)self);
    
    SESchemeParser* parser = [[SESchemeParser alloc] initWithString: textStorage.string];
    parser.delegate = self;
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    [parser parse];
    NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
    NSLog(@"Parsing & Highlighting took %lf seconds.", endTime-startTime);
}


- (BOOL) expandRange: (NSRange*) rangePtr toParMatchingPar: (unichar) par {

    NSTextStorage* textStorage = self.textEditorView.textStorage;
    switch (par) {
        case ')': {
            while ((*rangePtr).location > 0) {
                // Search left:
                (*rangePtr).length += 1;
                (*rangePtr).location -= 1;
                unichar matchingPar = [textStorage.string characterAtIndex: (*rangePtr).location];
                NSColor* color = [textStorage attribute: NSForegroundColorAttributeName atIndex: (*rangePtr).location effectiveRange: NULL];
                if (color != self.commentColor && color != self.stringColor) {
                    if (matchingPar == '(') {
                        return YES;
                    }
                    if (matchingPar == ')') {
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
        case '(': {
            NSUInteger stringLength = textStorage.string.length;
            while (NSMaxRange(*rangePtr) < stringLength) {
                // Search left:
                (*rangePtr).length += 1;
                unichar matchingPar = [textStorage.string characterAtIndex: NSMaxRange(*rangePtr)-1];
                if (matchingPar == ')') {
                    return YES;
                }
                if (matchingPar == '(') {
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


- (void) flashParCorrespondingToParAtIndex: (NSUInteger) index {
        
    NSTextStorage* textStorage = self.textEditorView.textStorage;
    
    if (index >= textStorage.string.length) {
        return;
    }
    
    NSColor* colorAtIndex = [textStorage attribute:NSForegroundColorAttributeName atIndex:index effectiveRange:NULL];
    
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
    NSRange flashingParRange = NSMakeRange(index, 1);
    BOOL match = [self expandRange: &flashingParRange toParMatchingPar: par];
    
    if (match) {
        
        [textStorage invertParsAtRange: flashingParRange];
        flashParTimer = [NSTimer timerWithTimeInterval: 1.0 repeats: NO block: ^(NSTimer *timer) {
            [textStorage invertParsAtRange: flashingParRange];
        }];
        [[NSRunLoop currentRunLoop] addTimer: flashParTimer forMode: NSDefaultRunLoopMode];
        
        NSLog(@"found par match at %@", NSStringFromRange(flashingParRange));
    } else {
        NSLog(@"Should find par matching '%c'", par);
    }
}

- (void) textDidChange: (NSNotification*) notification {
    NSLog(@"Editor changed text.");
}

void OPRunBlockAfterDelay(NSTimeInterval delay, void (^block)(void)) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*delay),
                   dispatch_get_current_queue(), block);
}
 

- (void) textViewDidChangeSelection: (NSNotification*) notification {
    NSRange newRange = [[[notification.object selectedRanges] lastObject] rangeValue];
    NSRange oldRange = [[notification.userInfo objectForKey: @"NSOldSelectedCharacterRange"] rangeValue];
    
    if (newRange.length+oldRange.length == 0 && (newRange.location+1 == oldRange.location || newRange.location == oldRange.location+1)) {
        NSLog(@"Cursor moved one char.");
        
        //OPRunBlockAfterDelay(0.0, ^{
            [self flashParCorrespondingToParAtIndex: MIN(oldRange.location, newRange.location)];
        //});
    }
    
    NSLog(@"Selection changed from %@ to %@", NSStringFromRange(oldRange), NSStringFromRange(newRange));
}



@end
