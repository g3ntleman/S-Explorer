//
//  OPTerminalView.m
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "OPTerminalView.h"

typedef struct {
    unichar character;
    int attrs;
} OPAttributedChar;

@implementation OPTerminalView {
    unichar screenContent[24+1][80+1];
    int foregroundAttrs[24+1][80+1];
    int backgroundAttrs[24+1][80+1];
}

@synthesize cursorPosition;

- (id) init {
    return [super init];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
    }
    return self;
}

- (void) awakeFromNib {
    cursorPosition.column = 1;
    cursorPosition.row = 1;
    //NSLog(@"%@ awoke.", self);
}

- (void) setNeedsDisplay:(BOOL)flag {
    [super setNeedsDisplay:flag];
    if (flag) {
        NSLog(@"-setNeedsDisplay: YES called: %@", self);
    }
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
    
    cursorPosition.row = row;
    cursorPosition.column = col;
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
        *foregroundPtr = foregroundAttrs[cursorPosition.row][cursorPosition.column];
    }
    if (backgroundPtr) {
        *backgroundPtr = backgroundAttrs[cursorPosition.row][cursorPosition.column];
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
        screenContent[cursorPosition.row][cursorPosition.column] = c;
        cursorPosition.column += 1;

        // Wrap if neccessary or LF occured:
        if (c == '\n' || cursorPosition.column>80) {
            cursorPosition.column = 1;
            cursorPosition.row += 1;
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
    return 0;
}


/* beInsertRow -
 *
 * Given a row number or CUR_ROW, TOP_EDGE or BOTTOM_EDGE as an input,
 * this function will scroll all text from the current row down down by one,
 * and create a blank row under the cursor.
 */
- (int) insertRow: (int) row {
    return 0;
}


/* beTransmitText -
 *
 * Given a pointer to text and byte count, this routine should transmit data
 * to whatever host made the request it's responding to. Typically this routine
 * should transmit data as though the user had typed it in.
 */
- (int) transmitText: (char*) text length: (int) len {
    return 0;
}


/* beAdvanceToTab -
 *
 * This routine will destructively advance the cursor to the
 * next set tab, or to the end of the line if there are no
 * more tabs to the right of the cursor.
 */

- (int) advanceToTab {
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
    return 0;
}

@end
