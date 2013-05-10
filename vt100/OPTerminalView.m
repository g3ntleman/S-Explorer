//
//  OPTerminalView.m
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "OPTerminalView.h"

#define rowHeight 14.0
#define colWidth  7.0

#define SCOLLBACKROWS 10000

#define charAt(row,col) screenContent[(row-1)*_size.columns+(col)-1]

typedef struct {
    unichar character;
    uint32 attrs;
} OPAttributedScreenCharacter;


@implementation OPTerminalView {
    OPAttributedScreenCharacter* screenContent;
    CGGlyph glyphCache[256];
}

- (BOOL) isFlipped {
    return YES;
}

- (void) load {
}

@synthesize cursorPosition;

- (id) initWithFrame: (NSRect) frameRect {
    if (self = [super initWithFrame: frameRect]) {
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSLog(@"%@ did become key.", note.object);
            [self setNeedsDisplay: YES];
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSLog(@"%@ NSApplicationDidBecomeActiveNotification", note.object);
            [self setNeedsDisplay: YES];
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSLog(@"%@ NSApplicationDidResignActiveNotification.", note.object);
            [self setNeedsDisplay: YES];
        }];        
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (CGGlyph*) glyphCache {
    return glyphCache;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [self initWithFrame:NSZeroRect]) {
    }
    return self;
}

- (void)keyDown:(NSEvent *)theEvent {
    // Forward to key responder:
    [self.keyResponder keyDown: theEvent];
}

- (void) setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    CGSize frameSize = self.frame.size;
    _size.rows = floor(frameSize.height / rowHeight);
    _size.columns = floor(frameSize.width / colWidth);
    
    if (screenContent) free(screenContent);
    screenContent = calloc(SCOLLBACKROWS*_size.columns, sizeof(OPAttributedScreenCharacter));
}

- (void) awakeFromNib {
    cursorPosition.column = 1;
    cursorPosition.row = 1;
    //NSLog(@"%@ awoke.", self);
}

- (void) setNeedsDisplay:(BOOL)flag {
    [super setNeedsDisplay:flag];
//    if (flag) {
//        NSLog(@"-setNeedsDisplay: YES called: %@", self);
//    }
}

/* beAbsoluteCursor -
 *
 * Given an input row and column, move the cursor to the
 * absolute screen coordinates requested. Note that if the
 * display window has scrollbars, the column is adjusted
 * to take that into account, but the row is not. This allows
 * for large scrollback in terminal windows.
 *
 * ROW must be able to accept CUR_ROW, TOP_EDGE, BOTTOM_EDGE,
 * or a row number.
 *
 * COLUMN must be able to accept CUR_COL, LEFT_EDGE, RIGHT_EDGE,
 * or a column number.
 */
- (int) setAbsoluteCursorRow: (int) row column: (int) col {
    
    if (col != CUR_COL) {
        if (col==LEFT_EDGE) col = 1;
        if (col==RIGHT_EDGE) col = self.size.columns;
        cursorPosition.column = col;
    }
    
    if (row != CUR_ROW) {
        if (row==TOP_EDGE) row = 1;
        if (row==BOTTOM_EDGE) row = self.size.rows;
        cursorPosition.row = row;
    }
    
    NSLog(@"Cursor moved to (%d,%d).", cursorPosition.row, cursorPosition.column);

    [self setNeedsDisplay: YES];
    return 0;
}


/* beOffsetCursor -
 *
 * Given an input row and column offset, move the cursor by that
 * many positions. For instance, row=0 and column=-1 would move
 * the cursor left a single column.
 *
 * If the cursor can't move the requested amount, results are
 * unpredictable.
 */
- (int) setOffsetCursorRow: (int) rowOffset column: (int) columnOffset {
    cursorPosition.row += rowOffset;
    cursorPosition.column += columnOffset;
    
    NSLog(@"Cursor moved by (%d,%d) to (%d,%d).", rowOffset, columnOffset, cursorPosition.row, cursorPosition.column);
    [self setNeedsDisplay: YES];
    return 0;
}


/* beRestoreCursor -
 *
 * Saved cursor position should be stored in a static
 * variable in the back end. This function restores the
 * cursor to the position stored in that variable.
 */
- (int) restoreCursor {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beSaveCursor -
 *
 * The back-end should maintain a static variable with the
 * last STORED cursor position in it. This function replaces
 * the contents of that variable with the current cursor position.
 * The cursor may be restored to this position by using the
 * beRestoreCursor function.
 */
- (int) saveCursor {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beGetTextAttributes -
 *
 * given a pointer to 'fore'ground and 'back'ground ints,
 * fill them with a device-independant description of the
 * current foreground and background colors, as well as any
 * font information in the foreground variable.
 */
- (int) getTextForegroundAttributes: (int*) foregroundPtr backgroundAttributes: (int*) backgroundPtr {
    if (foregroundPtr) {
        *foregroundPtr = charAt(cursorPosition.row,cursorPosition.column).attrs;
    }
    if (backgroundPtr) {
        *backgroundPtr = charAt(cursorPosition.row,cursorPosition.column).attrs;
    }
    return 0;
}


/* beSetTextAttributes -
 *
 * Given a foreground and a background device independant (SC) color and font
 * specification, apply these to the display, and save the state in the
 * static screen variables.
 *
 * Note that many font-specific constants (bold/underline/reverse, G0/G1/ASCII)
 * are stored ONLY in the foreground specification.
 */
- (int) setTextForegroundAttributes: (int) fore backgroundAtributes: (int) back {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beRawTextOut-
 *
 * The name of this function is misleading. Given a pointer to
 * ascii text and a count of bytes to print, print them to the
 * display device. If wrapping is enabled, wrap text. If there is a
 * scrolling region set and the cursor is in it,
 * scroll only within that region. 'beRawTextOut' means that it's guaranteed
 * not to have control sequences within the text.
 */
- (int) writeRawText: (char*) text length: (unsigned) length {
    
    for (unsigned pos = 0; pos<length; pos++) {
        unichar c = text[pos];
        
        // Put text at cursor position:
        charAt(cursorPosition.row,cursorPosition.column).character = c;
        cursorPosition.column += 1;

        // Wrap if neccessary:
        if (cursorPosition.column > self.size.columns) {
            [self setAbsoluteCursorRow: cursorPosition.row+1 column: 1];
        }
    }
    
    NSString* string = [[NSString alloc] initWithBytes: text
                                                length: length
                                              encoding: NSISOLatin1StringEncoding];
    NSLog(@"print '%@'", string);
    
    [self setNeedsDisplay: YES];
    
    return 0;
}


/* beEraseText -
 *
 * Given a 'from' and a 'to' position in display coordinates,
 * this function will fill in all characters between the two
 * (inclusive) with spaces. Note that the coordinates do NOT
 * specify a rectangle. erasing from (1,1) to (2,2) erases
 * all of the first row, and the first two characters of the
 * second.
 *
 * Note that this routine must be able to handle TOP_EDGE,
 * BOTTOM_EDGE, LEFT_EDGE, RIGHT_EDGE, CUR_ROW, and CUR_COL
 * in the appropriate parameters.
 */
- (int) eraseTextFromRow: (int) rowFrom andColumn: (int) colFrom toRow: (int) rowTo andColumn: (int) colTo{
    
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beDeleteText -
 *
 * Given a screen cursor 'from' and 'to' position, this function
 * will delete all text between the two. Text will be scrolled
 * up as appropriate to fill the deleted space. Note that, as in
 * beEraseText, the two coordinates don't specify a rectangle, but
 * rather a starting position and ending position. In other words,
 * deleting from (1,1) to (2,2) should move the text from (2,3) to the
 * end of the second row to (1,1), move line 3 up to line 2, and so on.
 *
 * This function must be able to process TOP_EDGE, BOTTOM_EDGE, LEFT_EDGE,
 * RIGHT_EDGE, CUR_ROW, and CUR_COL specifications in the appropriate
 * variables as well as regular row and column specifications.
 */
- (int) deleteTextFromRow: (int) rowFrom andColumn: (int) colFrom toRow: (int) rowTo andColumn: (int) colTo {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beInsertRow -
 *
 * Given a row number or CUR_ROW, TOP_EDGE or BOTTOM_EDGE as an input,
 * this function will scroll all text from the current row down down by one,
 * and create a blank row under the cursor.
 */
- (int) insertRow: (int) row {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beTransmitText -
 *
 * Given a pointer to text and byte count, this routine should transmit data
 * to whatever host made the request it's responding to. Typically this routine
 * should transmit data as though the user had typed it in.
 */
- (int) transmitText: (char*) text length: (int) len {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beAdvanceToTab -
 *
 * This routine will destructively advance the cursor to the
 * next set tab, or to the end of the line if there are no
 * more tabs to the right of the cursor.
 */

- (int) advanceToTab {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beClearTab -
 *
 * This function accepts a constant, and will try to clear tabs
 * appropriately. Its argument is either
 * ALL_TABS, meaning all tabs should be removed
 * CUR_COL, meaning the tab in the current column should be wiped, or
 * a column value, meaning if there's a tab there it should be wiped.
 *
 */
- (int) clearTab: (int) col {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beSetScrollingRows -
 *
 * Given a pair of row numbers, this routine will set the scrolling
 * rows to those values. Note that this routine will accept
 * TOP_ROW and BOTTOM_ROW as values, meaning that scrolling should
 * be enabled for the entire display, regardless of resizing.
 */
- (int) setScrollingFromRow: (int) fromRow toRow: (int) toRow {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}


/* beRingBell -
 *
 *  Ring the system bell once.
 */
- (int) ringBell {
    NSBeep();
    return 0;
}


/* beGetTermMode -
 *
 * Return the value of conTermMode, which is the terminal settings which
 * can be queried/set by <esc>[?#h/l.
 */
- (int) termMode {
    return 0;
}


/* beSetTermMode -
 *
 * Set the terminal as requested, assuming we can. Right now we only handle a
 * couple of the possible flags, but we store many of the others.
 */
- (int) setTermMode: (int) newMode {
    NSLog(@"Warning! Unimplemented call to %@", NSStringFromSelector(_cmd));
    return 0;
}

//- (NSString*) screenDescription {
//    NSMutableString* result = [NSMutableString stringWithString: [super description]];
//    OPCharSize size = self.size;
//    for (unsigned row = 1; row<=size.rows; row++) {
//        OPAttributedScreenCharacter* rowArray = screenContent[row]+1;
//        unsigned len = 0;
//        while (len<size.columns && rowArray[len].character && rowArray[len].character!='\n') {
//            len += 1;
//        }
//        
//        NSString* rowContent = [[NSString alloc] initWithCharacters: rowArray length: len];
//        [result appendFormat: @"\n%@", rowContent];
//    }
//    return result;
//}

//- (NSString*) description {
//    
//    return result;
//}

- (NSFont*) font {
    if (! _font) {
        _font = [NSFont fontWithName:@"Menlo-Bold" size: 11.0];
        
        // Build glyph cache:
        unichar chars[256];
        for (unsigned i=0; i<256; i++) {
            chars[i] = i;
        }
        CTFontRef fontRef = (__bridge CTFontRef)self.font;
        CTFontGetGlyphsForCharacters(fontRef, chars, glyphCache, 256);
    }
    return _font;
}

- (BOOL) canBecomeKeyView {
    return YES;
}

- (BOOL) acceptsFirstResponder {
    return YES;
}

- (BOOL) becomeFirstResponder {
    [self setNeedsDisplay: YES];
    return YES;
}

- (BOOL) resignFirstResponder {
    [self setNeedsDisplay: YES];
    return YES;
}

- (void) drawRect:(NSRect)dirtyRect {
    
    CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
    
    // Draw Background:
    CGContextSetFillColorWithColor(context, [[NSColor whiteColor] CGColor]);
    CGContextFillRect(context, dirtyRect);
    
    // Draw all characters:
    CGFontRef fontRef = CTFontCopyGraphicsFont((__bridge CTFontRef)self.font, NULL);
    CGContextSetFont(context, fontRef);
    // CGFontGetFontBBox(<#CGFontRef font#>)
    CGContextSetFontSize(context, self.font.pointSize);
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetStrokeColorWithColor(context, [[NSColor blackColor] CGColor]);
    CGContextSetFillColorWithColor(context, [[NSColor blackColor] CGColor]);

    CGContextSetTextMatrix(context, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0) );

    for (unsigned row = 1; row<=_size.rows; row++) {
        //OPAttributedScreenCharacter* rowArray = &charAt(row,1);
        
        for (unsigned col = 1; col <= _size.columns; col++) {
//            unsigned len = 0;
//            if (len>80 || rowArray[col]!=0 || rowArray[col]!='\n') {
//                break;
//            }
            CGPoint lineStart = CGPointMake(col*colWidth, row*rowHeight);
            unichar character = charAt(row,col).character;
            if (character) {
                CGGlyph glyph = [self glyphCache][character];
                // Draw single glyph:
                CGContextShowGlyphsAtPoint(context, lineStart.x, lineStart.y, &glyph, 1);
            }
        }
        
        //NSString* rowContent = [[NSString alloc] initWithCharacters: rowArray length: len];
        //[rowContent drawAtPoint:lineStart withAttributes:nil];
    
    }
    
//    if (! [NSApp isActive]) {
//        CGContextSetFillColorWithColor(context, [[NSColor lightGrayColor] CGColor]);
//    }
    
    if (self.window.isKeyWindow && self.window.firstResponder == self) {
        CGRect cursorRect = CGRectMake(cursorPosition.column*colWidth, cursorPosition.row*rowHeight-10.0, 1, rowHeight);
        CGContextFillRect(context, cursorRect);
    }
    
    //NSLog(@"Cursor draw: key = %d", self.window.isKeyWindow);

    CFRelease(fontRef);
}

@end
