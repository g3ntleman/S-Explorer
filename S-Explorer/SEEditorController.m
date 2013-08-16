//
//  SEEditorController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 16.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEEditorController.h"
#import "NoodleLineNumberView.h"

@implementation SEEditorController

- (void) parser: (SESchemeParser*) parser
     foundToken: (TokenOccurrence) tokenInstance
        atDepth: (NSInteger) depth
   elementCount: (NSUInteger) elementCount {
    
    NSTextStorage* textStorage = self.textEditorView.textStorage;
    
    switch (tokenInstance.token) {
        case COMMENT: {
            NSDictionary* commentAttributes = @{NSForegroundColorAttributeName: [NSColor greenColor]};
            [textStorage addAttributes: commentAttributes range: tokenInstance.occurrence];
            break;
        }
        case ATOM: {
            if (elementCount == 0 && depth>=1) {
                NSColor* color = nil;
                NSString* word = [textStorage.string substringWithRange: tokenInstance.occurrence];
                
                
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

- (void) flashBraceCorrespondingTo {
    
}

- (void) textDidChange: (NSNotification*) notification {
    NSLog(@"Editor changed text: %@", notification.object);
}


@end
