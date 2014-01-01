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

@synthesize interpreterAttributes = _interpreterAttributes;
@synthesize font = _font;


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
    self.automaticQuoteSubstitutionEnabled = NO;
    self.automaticDashSubstitutionEnabled = NO;
    self.automaticTextReplacementEnabled = NO;
    self.automaticSpellingCorrectionEnabled = NO;
    //
    //    [self.textStorage beginEditing];
    //    [self.textStorage setAttributes: self.typingAttributes range:NSMakeRange(0, self.textStorage.string.length)];
    //    [self.textStorage endEditing];
    //NSLog(@"%@ awoke.", self);
    self.font = [NSFont fontWithName:@"Menlo-Bold" size: 13.0];
    
    
    [self.textStorage setAttributes: self.interpreterAttributes range: NSMakeRange(0, self.textStorage.length)];
    self.typingAttributes = self.commandAttributes;
//    NSMutableDictionary* typingAttributes = [self.typingAttributes mutableCopy];
//    typingAttributes[BKTextCommandAttributeName] = @1;
    //self.typingAttributes = self.commandAttributes;
    commandLocation = self.string.length;
    
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


- (BOOL) becomeFirstResponder {
    
    NSTextStorage* textStorage = self.textStorage;

    if (! textStorage.string) {
        //[self.comm]
    }
    
    return [super becomeFirstResponder];
}

- (void) setFont:(NSFont *)font {
    
    _font = font;
    
    [self.textStorage beginEditing];
    
    [self.textStorage addAttribute: NSFontAttributeName
                             value: font
                             range: NSMakeRange(0, self.string.length)];
    
    [self.textStorage endEditing];
}

- (NSFont*) font {
    return _font;
}


- (NSDictionary*) interpreterAttributes {

    if (! _interpreterAttributes) {
        _interpreterAttributes = @{NSFontAttributeName: self.font,
                                   NSBackgroundColorAttributeName: [NSColor whiteColor],
                                   NSForegroundColorAttributeName: [NSColor blackColor]};
    }
    return _interpreterAttributes;
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
    
    // Insert plain text only:
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSString *pbItem = [pb readObjectsForClasses: @[[NSString class],[NSAttributedString class]] options:nil].lastObject;
    if ([pbItem isKindOfClass:[NSAttributedString class]]) {
        pbItem = [(NSAttributedString *)pbItem string];
    }
    
    [self insertText: pbItem];
}

- (NSString*) command {
    return [self.textStorage.string substringWithRange: self.commandRange];
}


- (void) setCommand:(NSString *)newCurrentCommand {
    
    NSParameterAssert(newCurrentCommand);
    
    NSTextStorage* textStorage = self.textStorage;
    NSRange commandRange = self.commandRange;
    [textStorage beginEditing];
    [textStorage replaceCharactersInRange: commandRange withString: newCurrentCommand];
    commandRange.length = newCurrentCommand.length;
    [textStorage setAttributes: self.typingAttributes range: commandRange];
    [textStorage endEditing];
    
    // Place cursor behind new command:
    self.selectedRange = NSMakeRange(NSMaxRange(commandRange), 0);
}


- (IBAction) insertTab: (id) sender {
    if (self.isCommandMode) {
        NSBeep(); // not implemented yet
        return;
    }
    [self insertText: @""];
}

/**
 * Returns the range of the interpreter output.
 */
- (NSRange) interpreterRange {
    NSAssert(commandLocation>=_prompt.length, @"Wrong commandLocation.");
    return NSMakeRange(0, commandLocation-_prompt.length);
}

/**
 * Returns the range of the current command, entered by the user.
 */
- (NSRange) commandRange {
    NSAssert(commandLocation<=self.textStorage.length, @"Wrong commandLocation.");
    return NSMakeRange(commandLocation, self.textStorage.length-commandLocation);
}

/**
 * Returns the range of the current prompt between the interpreter string and the command string.
 */
- (NSRange) promptRange {
    NSAssert(commandLocation>=_prompt.length, @"Wrong commandLocation.");
    return NSMakeRange(commandLocation-_prompt.length, _prompt.length);
}


- (void) appendInterpreterString: (NSString*) aString {

    NSTextStorage* textStorage = self.textStorage;
    
    //self.typingAttributes = self.interpreterAttributes;
    
    [textStorage beginEditing];
    
    NSRange range = [self promptRange];
    range.length = 0;
    //[textStorage replaceCharactersInRange: range withString: aString];
    [textStorage replaceCharactersInRange: range withAttributedString: [[NSAttributedString alloc] initWithString: aString attributes:self.interpreterAttributes]];
    commandLocation += aString.length;
    [textStorage endEditing];
    
    [self.enclosingScrollView flashScrollers];
}

//- (void) setEditable: (BOOL) flag {
//    [super setEditable: flag];
//    if (! [self.textStorage.string hasSuffix: self.prompt]) {
//        [self.textStorage beginEditing];
//        [self.textStorage replaceCharactersInRange:NSMakeRange(commandLocation, 0) withString: self.prompt];
//        commandLocation += self.prompt.length;
//        [self.textStorage endEditing];
//    }
//}

/**
 * Returns true, if the selection is at the end of the text,
 * where the user can enter text.
 **/
- (BOOL) isCommandMode {
    BOOL isCommandMode = (self.selectedRange.location >= commandLocation);
    return isCommandMode;
}

- (BOOL) shouldChangeTextInRange: (NSRange) affectedCharRange
               replacementString: (NSString*) replacementString {
    
    // Only allow editing the command string:
    if (affectedCharRange.location < commandLocation) {
        // TODO: Just move selection to the end of the command string?
        return NO;
    }
    
    return [super shouldChangeTextInRange: affectedCharRange replacementString: replacementString];
}

- (void) setPrompt:(NSString *)prompt {

    NSParameterAssert(prompt);
    
    NSLog(@"Setting Prompt on '%@' to '%@'", self.textStorage.string, prompt);

    [self.textStorage beginEditing];
    
    NSRange promptRange = [self promptRange];
    [self.textStorage replaceCharactersInRange: promptRange withAttributedString: [[NSAttributedString alloc] initWithString: prompt attributes:self.interpreterAttributes]];
    // Adjust commandLocation to make up for any length change:
    commandLocation += prompt.length - promptRange.length;
    _prompt = prompt;
    
    [self.textStorage endEditing];
}


- (NSDictionary*) typingAttributes {
    return self.commandAttributes;
}

/**
 * Ignores argument and always sets commandAttributes as typingAttributes.
 */
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

- (void) setString:(NSString *)string {
    [super setString:string];
}

/**
 * Sets the interpreter string, keeping the prompt at the end. Removes current command. Does not colorize.
 */
- (void) setInterpreterString:(NSString *)string {
    
    string = string ? : @"";
    
    [self.textStorage beginEditing];
    
    NSRange interpreterRange = self.interpreterRange;
    [self.textStorage replaceCharactersInRange: interpreterRange withAttributedString: [[NSAttributedString alloc] initWithString: string attributes:self.interpreterAttributes]];
    // Adjust commandLocation to make up for any length change:
    commandLocation += string.length - interpreterRange.length;
    
    [self.textStorage endEditing];
}

//- (void) setInterpreterString:(NSString *)string {
//    
//    
//    
//    if (!_prompt.length) {
//        [super setString: string];
//    } else {
//        string = string ? : @"";
//        NSMutableString* promptedString = [string mutableCopy];
//        if (sef.prompt.length) {
//        [promptedString appendString: self.prompt];
//        }
//        [self setString: promptedString];
//    }
//    commandLocation = self.string.length; // includes prompt
//}

- (IBAction) clear: (id) sender {
    
    self.interpreterString = @"";
}

- (void) insertText: (id) insertString {
    if (! self.isCommandMode) {
        [self moveToEndOfDocument: self];
        //self.selectedRange = NSMakeRange(self.string.length, 0);
    }
    [super insertText: insertString];
}

@end
