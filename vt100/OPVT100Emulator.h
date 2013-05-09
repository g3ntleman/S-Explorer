/* Originally vt100.h
 *
 * AUTHOR:  John L. Miller, johnmil@cs.cmu.edu / johnmil@jprc.com
 * DATE:   08/04/1996
 *
 * AUTHOR:  Dirk Theisen, d.theisen@objectpark.org
 * DATE:   05/09/2013
 *
 * Copyright (c) 1996 John L. Miller
 * Extended and converted by Dirk Theisen
 * 
 * 
 *
 * Full permission is granted to use, modify and distribute
 * this code, provided:
 * 1) This comment field is included in its entirity
 * 2) No money is charged for any work including or based on 
 *    portions of this code.
 *
 * If you're a nice person and find this useful, I'd appreciate a
 * note letting me know about it. e-mail is usually what spurs me
 * on to improve and support software I've written.
 *
 */


/* This identifier should be spit back to the computer when a terminal
 * id is requested.
 */
#define ANSWERBACK_MESSAGE "vt100"

/* Various terminal-related modes Entries are as follows:
 *         Identification       esc. ID    If set,         if clear
 */

/* Keyboard action         2       Locked          Unlocked */
#define CAPS_MODE         0x00000001
/* Insertion               4       Insert          Overwrite  */
#define INSERT_MODE       0x00000002
/* Send - Receive          12      Full            Echo */
#define FULLDUPLEX_MODE   0x00000004
/* Line feed/New line      20      New line        Line feed */
#define NEWLINE_MODE      0x00000008


#define NUM_TERM_ATTR_MODES 9   /* We only track eight '?' escape sequences */

/* Cursor key              ?1      Application     Cursor */
#define CURSORAPPL_MODE   0x00000010
/* ANSI/VT52               ?2      ANSI            VT52 */
#define ANSI_MODE         0x00000020
/* Column                  ?3      132             80 */
#define COL132_MODE       0x00000040
/* Scrolling               ?4      Smooth          Jump  */
#define SMOOTHSCROLL_MODE 0x00000080
/* Screen                  ?5      Reverse         Normal */
#define REVSCREEN_MODE    0x00000100
/* Origin                  ?6      Relative        Absolute */
#define ORIGINREL_MODE    0x00000200
/* Wraparound              ?7      Wrap            Truncate */
#define WRAP_MODE         0x00000400
/* Auto key repeat         ?8      Repeating       No repeat */
#define REPEAT_MODE       0x00000800


/* Print form feed         ?18     Yes             No */
#define PRINTFF_MODE      0x00001000
/* Print extent            ?19     Full screen     Scrolling region */
#define PRINTFULLSCR_MODE 0x00002000
/* Keypad application 'Esc ='    numeric 'Esc >' */
#define KEYPADNUMERIC_MODE 0x00004000
/* default mode that we start the emulator with */
#define DEFAULT_MODE      (NEWLINE_MODE|ANSI_MODE|REPEAT_MODE)

/* This constant is VERY important - the size of the buffer for
 * unprocessed vt-100 prints!
 */
#define MAXVTBUFLEN       4096

/* Constants used in place of actual row and column numbers
 * for the cursor movement and text erasing and deleting functions.
 */
#define CUR_ROW   -999
#define CUR_COL   -999
#define ALL_TABS  -1999

#define LEFT_EDGE 0
#define RIGHT_EDGE 12000
#define TOP_EDGE 0
#define BOTTOM_EDGE 12000

/* Text attribute definitions; color, font, bold. */
#define NUM_SC_ATTRIBUTES   11

#define SC_RED   0x0001
#define SC_GREEN 0x0002
#define SC_BLUE  0x0004
#define SC_BOLD  0x0010
#define SC_UL    0x0020 /* Underlined */
#define SC_BL    0x0040 /* Blinking */
#define SC_RV    0x0080 /* Reverse video */
#define SC_ASCII    0x0100 /* Normal ASCII (USASCII) */
#define SC_G0       0x0200 /* graphics set G0 */
#define SC_G1       0x0400 /* Graphics set G1 */
#define SC_GRAPHICS 0x0800 /* Good question */



@protocol OPVT100EmulatorDelegate <NSObject>

/* Prototype for functions which MUST BE SUPPLIED BY THE BACK END!!! */

/* Back-end specific initialization is performed in this function.
 * this is gauranteed to be called before any other requests are made
 * of the back end.
 */

/* beInitVT100Terminal() - 
 *
 * This function is called by the VT100 emulator as soon as the 
 * front-end terminal is initialized. It's responsible for setting
 * initial state of the terminal, and initing our many wacky variables.
 */
//int beInitVT100Terminal();


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
- (int) setAbsoluteCursorRow: (int) row column: (int) col;


/* beOffsetCursor -
 * 
 * Given an input row and column offset, move the cursor by that
 * many positions. For instance, row=0 and column=-1 would move
 * the cursor left a single column.
 *
 * If the cursor can't move the requested amount, results are 
 * unpredictable.
 */
- (int) setOffsetCursorRow: (int) row column: (int) column;


/* beRestoreCursor -
 * 
 * Saved cursor position should be stored in a static 
 * variable in the back end. This function restores the 
 * cursor to the position stored in that variable.
 */
- (int) restoreCursor;


/* beSaveCursor -
 *
 * The back-end should maintain a static variable with the
 * last STORED cursor position in it. This function replaces
 * the contents of that variable with the current cursor position.
 * The cursor may be restored to this position by using the
 * beRestoreCursor function.
 */
- (int) saveCursor;


/* beGetTextAttributes -
 *
 * given a pointer to 'fore'ground and 'back'ground ints,
 * fill them with a device-independant description of the
 * current foreground and background colors, as well as any
 * font information in the foreground variable.
 */
- (int) getTextForegroundAttributes: (int*) foregroundPtr backgroundAttributes: (int*) backgroundPtr;


/* beSetTextAttributes -
 *
 * Given a foreground and a background device independant (SC) color and font
 * specification, apply these to the display, and save the state in the 
 * static screen variables.
 *
 * Note that many font-specific constants (bold/underline/reverse, G0/G1/ASCII)
 * are stored ONLY in the foreground specification.
 */
- (int) setTextForegroundAttributes: (int) fore backgroundAtributes: (int) back;


/* beRawTextOut-
 *
 * The name of this function is misleading. Given a pointer to
 * ascii text and a count of bytes to print, print them to the
 * display device. If wrapping is enabled, wrap text. If there is a
 * scrolling region set and the cursor is in it,
 * scroll only within that region. 'beRawTextOut' means that it's guaranteed
 * not to have control sequences within the text. 
 */
- (int) writeRawText: (char*) text length: (int) length;


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
- (int) eraseTextFromRow: (int) rowFrom andColumn: (int) colFrom toRow: (int) rowTo andColumn: (int) colTo;


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
- (int) deleteTextFromRow: (int) rowFrom andColumn: (int) colFrom toRow: (int) rowTo andColumn: (int) colTo;


/* beInsertRow -
 *
 * Given a row number or CUR_ROW, TOP_EDGE or BOTTOM_EDGE as an input, 
 * this function will scroll all text from the current row down down by one,
 * and create a blank row under the cursor.
 */
- (int) insertRow: (int) row;


/* beTransmitText -
 *
 * Given a pointer to text and byte count, this routine should transmit data 
 * to whatever host made the request it's responding to. Typically this routine
 * should transmit data as though the user had typed it in.
 */
- (int) transmitText: (char*) text length: (int) len;


/* beAdvanceToTab -
 *
 * This routine will destructively advance the cursor to the
 * next set tab, or to the end of the line if there are no
 * more tabs to the right of the cursor.
 */

- (int) advanceToTab;


/* beClearTab -
 *
 * This function accepts a constant, and will try to clear tabs
 * appropriately. Its argument is either
 * ALL_TABS, meaning all tabs should be removed
 * CUR_COL, meaning the tab in the current column should be wiped, or 
 * a column value, meaning if there's a tab there it should be wiped.
 *
 */
- (int) clearTab: (int) col;


/* beSetScrollingRows -
 *
 * Given a pair of row numbers, this routine will set the scrolling
 * rows to those values. Note that this routine will accept
 * TOP_ROW and BOTTOM_ROW as values, meaning that scrolling should
 * be enabled for the entire display, regardless of resizing.
 */
- (int) setScrollingFromRow: (int) fromRow toRow: (int) toRow;


/* beRingBell -
 *
 *  Ring the system bell once.
 */
- (int) ringBell;


/* beGetTermMode -
 * 
 * Return the value of conTermMode, which is the terminal settings which
 * can be queried/set by <esc>[?#h/l.
 */
- (int) termMode;


/* beSetTermMode -
 * 
 * Set the terminal as requested, assuming we can. Right now we only handle a 
 * couple of the possible flags, but we store many of the others. 
 */
- (int) setTermMode: (int) newMode;

@end

@interface OPVT100Emulator :  NSObject {
    int termAttrMode[NUM_TERM_ATTR_MODES];
    int alltermAttrModes;
}

@property (strong, nonatomic) id <OPVT100EmulatorDelegate> delegate;

- (void) puts: (char*) f;
- (void) printf: (char *) format, ... ;
- (int) processedTextOut: (char*) cbuf length: (size_t) count;

@end
