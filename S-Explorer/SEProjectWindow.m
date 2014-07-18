//
//  SEProjectWindow.m
//  S-Explorer
//
//  Created by Dirk Theisen on 27.01.14.
//  Copyright (c) 2014 Cocoanuts. All rights reserved.
//

#import "SEProjectWindow.h"

@implementation SEProjectWindow

- (void) keyDown: (NSEvent *) theEvent {
    
    // Try to do consistent alt-tab gehavior on all plattforms.
    // Check for alt-tab key-combo:
    if (theEvent.keyCode == 48 && theEvent.modifierFlags & NSAlternateKeyMask) {
        if ([self.firstResponder isKindOfClass: [NSView class]]) {
            NSView* firstResponder = self.firstResponder;
            while (! [firstResponder	 isKindOfClass: [NSOutlineView class]]) {
                firstResponder = firstResponder.superview;
            }
            
            [self makeFirstResponder: firstResponder.nextValidKeyView];
        }
        return;
    }
    
    [super keyDown: theEvent];
}

@end
