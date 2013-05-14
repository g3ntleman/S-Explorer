//
//  OPTerminalView.m
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "BRREPLView.h"


typedef struct {
    unichar character;
    uint32 attrs;
} OPAttributedScreenCharacter;

NSString* BKCurrentCommandAttributeName = @"BKCurrentCommand";


@implementation BRREPLView {
}


- (id) initWithFrame: (NSRect) frameRect {
    if (self = [super initWithFrame: frameRect]) {
        
//        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//            NSLog(@"%@ did become key.", note.object);
//            [self setNeedsDisplay: YES];
//        }];
//        [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//            NSLog(@"%@ NSApplicationDidBecomeActiveNotification", note.object);
//            [self setNeedsDisplay: YES];
//        }];
//        [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
//            NSLog(@"%@ NSApplicationDidResignActiveNotification.", note.object);
//            [self setNeedsDisplay: YES];
//        }];        
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}


- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [self initWithFrame:NSZeroRect]) {
    }
    return self;
}

//- (OPCharPosition) cursorScreenBufferPosition {
//    OPCharPosition cursorScreenBufferPosition;
//    cursorScreenBufferPosition.column = cursorPosition.column;
//    cursorScreenBufferPosition.row = cursorPosition.row + lastRowIndex-_terminalSize.rows;
//    return cursorScreenBufferPosition;
//}
//
//- (void) setCursorScreenBufferPosition: (OPCharPosition) position {
//    cursorPosition.column = position.column;
//    cursorPosition.row = position.row - lastRowIndex + _terminalSize.rows;
//}

- (BOOL) sendCurrentCommand {
    
    NSRange cursorRange = self.selectedRange;
    NSRange commandRange;
    if ([self.textStorage attribute: BKCurrentCommandAttributeName atIndex: cursorRange.location-1 effectiveRange: &commandRange]) {
        if (commandRange.length) {
            NSString* currentCommand = [self.textStorage.string substringWithRange: commandRange];
            NSLog(@"Sending command '%@'", currentCommand);
            
            [self.textStorage beginEditing];
            [self.textStorage replaceCharactersInRange:commandRange withString:@""];
            [self.textStorage endEditing];

            [self.replDelegate commitCommand: currentCommand];
            
            return YES;
        }
    }
    return NO;
}

- (void) keyDown: (NSEvent*) theEvent {
        
    //NSLog(@"Key pressed: %@", theEvent);
    
    self.typingAttributes = self.commandAttributes;
    
    NSString* charactersString = [theEvent characters];
    
    switch ([charactersString characterAtIndex: 0]) {
        case NSLeftArrowFunctionKey:
            NSLog(@"Left behind.");
            break;
        case NSRightArrowFunctionKey:
            NSLog(@"Right as always!");
            break;
        case NSDownArrowFunctionKey:
            NSLog(@"Downward is Heavenward");
            break;
        case NSUpArrowFunctionKey:
            NSLog(@"Up, up, and away!");
            break;
        case 13:
            NSLog(@"CR!");
            if ([self sendCurrentCommand]) {
                break;
            }
            // Otherwise, insert a blank line
            
        default: {
            [super keyDown: theEvent];
            break;
        }
            
            //        if (code) {
            //            inputData = [NSData dataWithBytes: code length: strlen(code)];
            //        }
            //
            //        if (inputData) {
            //            // Pipe keys entered by the user into the external task:
            //            [_inputPipe.fileHandleForWriting writeData: inputData];
            //        }
    }
    
    //[self scrollScreenBufferRowToVisible: self.cursorScreenBufferPosition.row];
}

- (NSDictionary*) interpreterAttributes {
    NSFont* interpreterFont = [NSFont fontWithName:@"Menlo-Regular" size: 12.0];
    NSMutableDictionary* interpreterAttributes = [[NSMutableDictionary alloc] init];
    [interpreterAttributes setObject: NSFontAttributeName forKey: interpreterFont];
    [interpreterAttributes setObject: [NSColor redColor] forKey: NSForegroundColorAttributeName];
    return interpreterAttributes;
}

- (void) appendString:(NSString *)aString {
    
    NSTextStorage* textStorage = self.textStorage;
    
    self.typingAttributes = self.interpreterAttributes;
    
    [textStorage beginEditing];
    //NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString: aString attributes: self.interpreterAttributes];
    //[textStorage replaceCharactersInRange: NSMakeRange(textStorage.string.length, 0)
    //                 withAttributedString: attributedString];
    [textStorage replaceCharactersInRange: NSMakeRange(textStorage.string.length, 0) withString: aString];
    
    [textStorage endEditing];
}

- (IBAction) clear: (id) sender {
    
    NSTextStorage* textStorage = self.textStorage;
    [textStorage beginEditing];
    [textStorage replaceCharactersInRange:NSMakeRange(textStorage.string.length, 0) withString: @""];
    [textStorage endEditing];

}

- (NSDictionary*) commandAttributes {
    self.font = [NSFont fontWithName:@"Menlo-Bold" size: 12.0];
    
    NSMutableDictionary* commandAttributes = [self.typingAttributes mutableCopy];
    [commandAttributes setObject:@YES forKey: BKCurrentCommandAttributeName];
    [commandAttributes setObject:self.font forKey: NSFontAttributeName];
    
    return commandAttributes;
}

- (void) awakeFromNib {

    // Start with a terminal in the size of the scroll view:
    self.frame = self.enclosingScrollView.bounds;
//    
//    [self.textStorage beginEditing];
//    [self.textStorage setAttributes: self.typingAttributes range:NSMakeRange(0, self.textStorage.string.length)];
//    [self.textStorage endEditing];
    //NSLog(@"%@ awoke.", self);
}

- (void) setNeedsDisplay:(BOOL)flag {
    [super setNeedsDisplay:flag];
//    if (flag) {
//        NSLog(@"-setNeedsD,isplay: YES called: %@", self);
//    }
}

- (BOOL) shouldChangeTextInRange: (NSRange) affectedCharRange
               replacementString: (NSString*) replacementString {
    
    NSRange fullRange;
    if (self.textStorage.length==NSMaxRange(affectedCharRange) && replacementString.length) {
        // We may always append:
        return YES;
    }
    if ([self.textStorage attribute: BKCurrentCommandAttributeName atIndex: affectedCharRange.location effectiveRange: &fullRange]) {
        if (NSMaxRange(fullRange)>=NSMaxRange(affectedCharRange)) {
            // The whole affectedRange is editable:
            return YES;
        }
    }
    NSBeep();
    return NO;
}





/* beRingBell -
 *
 *  Ring the system bell once.
 */
- (int) ringBell {
    NSBeep();
    return 0;
}



//- (BOOL) canBecomeKeyView {
//    return YES;
//}
//
//- (BOOL) acceptsFirstResponder {
//    return YES;
//}
//
//- (BOOL) becomeFirstResponder {
//    [self setNeedsDisplay: YES];
//    return YES;
//}
//
//- (BOOL) resignFirstResponder {
//    [self setNeedsDisplay: YES];
//    return YES;
//}


@end
