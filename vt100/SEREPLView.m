//
//  OPTerminalView.m
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEREPLView.h"

//NSString* BKTextCommandAttributeName = @"BKTextCommandAttributeName";

@implementation SEREPLView {
    NSUInteger commandLocation;
}


//- (id) initWithFrame: (NSRect) frameRect {
//    if (self = [super initWithFrame: frameRect]) {
//        
////        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
////            NSLog(@"%@ did become key.", note.object);
////            [self setNeedsDisplay: YES];
////        }];
////        [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
////            NSLog(@"%@ NSApplicationDidBecomeActiveNotification", note.object);
////            [self setNeedsDisplay: YES];
////        }];
////        [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
////            NSLog(@"%@ NSApplicationDidResignActiveNotification.", note.object);
////            [self setNeedsDisplay: YES];
////        }];        
//    }
//    return self;
//}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}


- (void) awakeFromNib {
    
    self.smartInsertDeleteEnabled = NO;
    //
    //    [self.textStorage beginEditing];
    //    [self.textStorage setAttributes: self.typingAttributes range:NSMakeRange(0, self.textStorage.string.length)];
    //    [self.textStorage endEditing];
    //NSLog(@"%@ awoke.", self);
    self.font = [NSFont fontWithName:@"Menlo-Bold" size: 13.0];
    
//    NSMutableDictionary* typingAttributes = [self.typingAttributes mutableCopy];
//    typingAttributes[BKTextCommandAttributeName] = @1;
    //self.typingAttributes = self.commandAttributes;
    
}


//- (void) keyDown: (NSEvent*) theEvent {
//        
//    //NSLog(@"Key pressed: %@", theEvent);
//    
//    //self.typingAttributes = self.commandAttributes;
//    
//    NSString* charactersString = [theEvent characters];
//    
//    switch ([charactersString characterAtIndex: 0]) {
//        case NSLeftArrowFunctionKey:
//            if ([self.textStorage attribute: BKTextCommandAttributeName atIndex: self.selectedRange.location-1 effectiveRange: NULL]) {
//                [super keyDown: theEvent];
//            }
//            break;
//            
////        case NSRightArrowFunctionKey:
////            NSLog(@"Right as always!");
////            break;
//        case NSDownArrowFunctionKey:
//            NSLog(@"Downward is Heavenward");
//            break;
//        case NSUpArrowFunctionKey:
//            NSLog(@"Up, up, and away!");
//            break;
//        case 13:
//            NSLog(@"CR!");
//            if ([self sendCurrentCommand]) {
//                break;
//            }
//            // Otherwise, insert a blank line
//            
//        default: {
//            [super keyDown: theEvent];
//            break;
//        }
//            
//            //        if (code) {
//            //            inputData = [NSData dataWithBytes: code length: strlen(code)];
//            //        }
//            //
//            //        if (inputData) {
//            //            // Pipe keys entered by the user into the external task:
//            //            [_inputPipe.fileHandleForWriting writeData: inputData];
//            //        }
//    }
//    
//    //[self scrollScreenBufferRowToVisible: self.cursorScreenBufferPosition.row];
//}


- (NSDictionary*) interpreterAttributes {
    
    NSMutableDictionary* interpreterAttributes = [[NSMutableDictionary alloc] init];
    interpreterAttributes[NSFontAttributeName] = self.font;
    interpreterAttributes[NSForegroundColorAttributeName] = [NSColor blackColor];

    return interpreterAttributes;
}

- (NSDictionary*) commandAttributes {
    
    NSMutableDictionary* commandAttributes = nil;
    
    if (self.font) {
        commandAttributes = [self.interpreterAttributes mutableCopy];
        //commandAttributes[BKTextCommandAttributeName] = @YES;
        commandAttributes[NSForegroundColorAttributeName] = [NSColor blueColor];
    }
    return commandAttributes;
}

- (void) setNeedsDisplay:(BOOL)flag {
    [super setNeedsDisplay:flag];
//    if (flag) {
//        NSLog(@"-setNeedsD,isplay: YES called: %@", self);
//    }
}

-(void) paste: (id) sender {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSString *pbItem = [pb readObjectsForClasses: @[[NSString class],[NSAttributedString class]] options:nil].lastObject;
    if ([pbItem isKindOfClass:[NSAttributedString class]]) {
        pbItem = [(NSAttributedString *)pbItem string];
    }
    
    //pbItem = [[NSAttributedString alloc] initWithString: pbItem attributes: self.typingAttributes];
//    if ([pbItem isEqualToString:@"foo"]) {
        [self insertText: pbItem];
//    }else{
//        [super paste:sender];
//    }
}

- (NSRange) commandRange {
    return NSMakeRange(commandLocation, self.string.length-commandLocation);
}

- (void) appendInterpreterString: (NSString*) aString {
    
    NSTextStorage* textStorage = self.textStorage;
    
    //self.typingAttributes = self.interpreterAttributes;
    
    [textStorage beginEditing];
    
    NSRange range = NSMakeRange(commandLocation, 0);
    [textStorage replaceCharactersInRange: range withString: aString];
    commandLocation += aString.length;
    range.length += aString.length;
    [textStorage setAttributes: self.interpreterAttributes range: range];
    [textStorage endEditing];
    self.typingAttributes = self.commandAttributes;
    
    
    
    [self.enclosingScrollView flashScrollers];
}

- (BOOL) shouldChangeTextInRange: (NSRange) affectedCharRange
               replacementString: (NSString*) replacementString {
    
    if (affectedCharRange.location<commandLocation) {
        NSBeep();
        return NO;
    }
    return YES;
}

/**
 * Returns true, if the selection is at the end of the text, 
 * where the user can enter text.
 **/
- (BOOL) isCommandMode {
    return (self.selectedRange.location >= commandLocation);
}


- (NSDictionary*) typingAttributes {
    return self.commandAttributes;
}

- (void) setTypingAttributes: (NSDictionary*) attrs {
    [super setTypingAttributes: self.commandAttributes];
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

- (IBAction) clear: (id) sender {
    
    self.string = @"";
    commandLocation = 0;
    
}

@end