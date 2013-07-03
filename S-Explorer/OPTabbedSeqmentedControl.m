//
//  OPTabbedSeqmentedControl.m
//  WeSync
//
//  Created by Dirk Theisen on 15.05.07.
//  Copyright 2007 Objectpark Software. All rights reserved.
//

#import "OPTabbedSeqmentedControl.h"

#define SEGMENT_HEIGHT 27.0
#define WINDOW_TITLE_HEIGHT 18
//#define SEGMENT_WIDTH ([self bounds].size.width / [self segmentCount])
//#define SEGMENT_WIDTH 200

@implementation OPTabbedSeqmentedControl


- (void) resizeWithOldSuperviewSize: (NSSize) oldSuperSize {

    if (self.autoresizingMask | NSViewWidthSizable) {
        // Adjust sizes of the cells proportionally:
        NSSize newSuperSize = self.superview.frame.size;
        CGFloat rest = 0.0;
        double factor = newSuperSize.width / oldSuperSize.width;
        NSUInteger count = self.segmentCount;
        for (int i=0; i < count; i++) {
            CGFloat oldWidth = [self widthForSegment: i];
            CGFloat newWidth = oldWidth * factor;
//            if (rest>=1.0) {
//                newWidth += floor(rest);
//                rest -= floor(rest);
//            }
//            CGFloat newRoundedWidth = floor(newWidth);
//            rest += newWidth-newRoundedWidth;
            
            [self setWidth: newWidth forSegment: i];
        }
    }
    [super resizeWithOldSuperviewSize: oldSuperSize];
}


- (id) initWithFrame: (NSRect) frame {
    
    if (self = [super initWithFrame:frame]) {
        // Initialization code here.
		//[self setSelectedSegment: 0];
    }
    return self;
}

- (void) awakeFromNib {
    NSLog(@"awakeFromNib");
}

//- (void) tabView: (NSTabView*) aTabView didSelectTabViewItem: (NSTabViewItem*) tabViewItem
//{
//	if (tabView == aTabView) {
//		[self setSelectedSegment: [tabView indexOfTabViewItem: tabViewItem]];
//	}
//}

//- (void) awakeFromNib 
//{
//	NSRect frame = [self frame];
//	frame.size.height = SEGMENT_HEIGHT;
//	NSRect bounds = [self bounds];
//	bounds.size = frame.size;
//	[self setFrame: frame];
//	[self setBounds: bounds];
//	[self setSelectedSegment: 0];
//	[self setTarget: self];
//	[self setAction: @selector(selectTabFromSegmentedControl:)];
//}
//
//- (void) mouseDown: (NSEvent*) event {
//	NSPoint point = [self convertPoint: [event locationInWindow] fromView: nil];
//	int i, xoffset = 0;
//	for (i = 0; i < [self segmentCount]; i++) {
//		float width = [self widthForSegment: i];
//		if (point.x>xoffset && point.x<xoffset+width) break;
//		xoffset += width;
//	}
//	if (i<[self segmentCount]) {
//		[self setSelectedSegment: i];
//		isDragging = YES;
//		[self setNeedsDisplay: YES];
//		[NSApp sendAction: [self action] to: [self target] from: self];
//	}
//}
//
//- (void) mouseUp: (NSEvent*) event {
//	isDragging = NO;
//	[self setNeedsDisplay: YES];
//}


- (void) drawRect2: (NSRect) rect {
    // Drawing code here.
	//[super drawRect: rect];
	
	// Draw background pattern:
	NSImage* background = [NSImage imageNamed: @"wood_tile"];
	
	[NSGraphicsContext saveGraphicsState];

	[[NSColor colorWithPatternImage: background] set];
	[[NSBezierPath bezierPathWithRect: [self bounds]] fill];
		
	[[NSColor blackColor] set];
	
	// Draw the shadows around background:
	NSShadow* backgroundShadow = [[NSShadow alloc] init];
	[backgroundShadow setShadowColor: [NSColor blackColor]];
	[backgroundShadow setShadowBlurRadius: 6];
	[backgroundShadow setShadowOffset: NSMakeSize(0,-1)];
	[backgroundShadow set];
	
	NSRect bounds = [self bounds];
	[[NSBezierPath bezierPathWithRect: NSMakeRect(0,-2,bounds.size.width, 2)] fill];
	[[NSBezierPath bezierPathWithRect: NSMakeRect(0,bounds.size.height,bounds.size.width, 2)] fill];
	[[NSBezierPath bezierPathWithRect: NSMakeRect(-2,0,2,bounds.size.height)] fill];
	[[NSBezierPath bezierPathWithRect: NSMakeRect(bounds.size.width,0,2,bounds.size.height)] fill];
	
	[NSGraphicsContext restoreGraphicsState];
	
	NSImage *middleImage;
	int i;
	int xoffset = 4;
	for (i = 0; i < [self segmentCount]; i++) {
		BOOL isSelected = [self selectedSegment] == i;
		float width = [self widthForSegment: i];
		
		//[[NSBezierPath bezierPathWithRect: NSMakeRect(xoffset, 0,width, 24)] stroke];

		
		if (isSelected) {
			
			[NSGraphicsContext saveGraphicsState];

			// Selected tab has a white background tab. Draw it!
			[isDragging ? [NSColor lightGrayColor] : [NSColor whiteColor] set];
			NSBezierPath* roundedBack = [NSBezierPath bezierPath];
			[roundedBack moveToPoint: NSMakePoint(xoffset+2,0)];
			[roundedBack relativeLineToPoint: NSMakePoint(0,16)];
			[roundedBack relativeCurveToPoint: NSMakePoint(6,6) controlPoint1: NSMakePoint(0,0) controlPoint2: NSMakePoint(0,6)];
			[roundedBack relativeLineToPoint: NSMakePoint(width-16,0)]; // horizontal top
			[roundedBack relativeCurveToPoint: NSMakePoint(6,-6) controlPoint1: NSMakePoint(0,0) controlPoint2: NSMakePoint(6,0)];
			[roundedBack relativeLineToPoint: NSMakePoint(0, -16)];
			[roundedBack closePath]; // horizontal bottom ;close shape
			[backgroundShadow set];

			[roundedBack fill];

			[NSGraphicsContext restoreGraphicsState];
			
			//NSImage* leftTabRound  = [NSImage imageNamed: @"TabLeft"];
			//			NSImage* rightTabRound = [NSImage imageNamed: @"TabRight"];
			//			
			//			
			//			
			//			[leftTabRound drawInRect: NSMakeRect(xoffset, 0, 6, 28)
			//							fromRect: NSZeroRect
			//						   operation: NSCompositeCopy
			//							fraction: 1.0];
			//			
			//			[rightTabRound drawInRect: NSMakeRect(xoffset + [self widthForSegment: i]-6, 0 , 6, 28)
			//							 fromRect: NSZeroRect
			//							operation: NSCompositeCopy
//							 fraction: 1.0];
			
			if (isDragging)
				middleImage = [NSImage imageNamed:@"middle_bar_down"];
			else
				middleImage = [NSImage imageNamed:@"middle_bar_selected"];
		} else
			middleImage = [NSImage imageNamed:@"middle_bar_normal"];
		
//		// draw the background
//		[middleImage drawInRect: NSMakeRect(SEGMENT_WIDTH * i, 0, SEGMENT_WIDTH, SEGMENT_HEIGHT)
//					   fromRect: NSZeroRect
//					  operation: NSCompositeSourceOver
//					   fraction: 1.0];
		
		
		

		// draw the divider
//		[[NSImage imageNamed:@"TabRight"] drawAtPoint: NSMakePoint((int)SEGMENT_WIDTH * i, 0)
//												fromRect: NSZeroRect
//											   operation: NSCompositeSourceOver
//												fraction: 1.0];
		
		// draw the icon
		NSImage* icon;
		
		// if the tab is selected and the user is currently dragging, darken the icon image
		if ([self selectedSegment] == i && isDragging && NO) {
			icon = [[NSImage alloc] initWithSize: [[self imageForSegment:i] size]];
			
			[icon lockFocus];
			
			[[self imageForSegment:i] compositeToPoint: NSZeroPoint operation: NSCompositeDestinationOver];
			[[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.5] set];
			
			[[NSGraphicsContext currentContext] setCompositingOperation: NSCompositeSourceAtop ];
			[NSBezierPath fillRect: NSMakeRect(0, 0, [icon size].width, [icon size].height)];
			
			[icon unlockFocus];
		} 
		else
			icon = [self imageForSegment: i];
		
		//[icon drawAtPoint: NSMakePoint(xoffset + (int)(SEGMENT_WIDTH - [[self imageForSegment:i] size].width) / 2, 0)/	
		[icon drawAtPoint: NSMakePoint(xoffset + 7, 2)
				 fromRect: NSZeroRect
				operation: NSCompositeSourceOver
				 fraction: isSelected ? 1.0 : 0.7];
		
		NSString* label = [self labelForSegment: i];
		
		static NSDictionary* selectedLabelAttributes = nil;
		if (!selectedLabelAttributes) {			
			selectedLabelAttributes = [[NSDictionary alloc] initWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 10], NSFontAttributeName, nil, nil];
		}
		
		static NSDictionary* otherLabelAttributes = nil;
		if (!otherLabelAttributes) {
			NSShadow* textShadow = [[NSShadow alloc] init];
			[textShadow setShadowOffset: NSMakeSize(+1.5,-1.5)];
			[textShadow setShadowBlurRadius: 1.0];
			[textShadow setShadowColor: [NSColor colorWithCalibratedWhite: 1.0 alpha: 0.6]];
			
			otherLabelAttributes = [[NSDictionary alloc] initWithObjectsAndKeys: [NSFont boldSystemFontOfSize: 10], NSFontAttributeName, textShadow, NSShadowAttributeName, [NSColor colorWithCalibratedWhite: 0.0 alpha: 0.7], NSForegroundColorAttributeName, nil, nil];
		}
		
		
		
		[label drawAtPoint: NSMakePoint(xoffset + 11 + [icon size].width, 4) withAttributes: isSelected ? selectedLabelAttributes : otherLabelAttributes];
		
		/*
		 NSFont			*font = [NSFont boldSystemFontOfSize:[[self font] pointSize]];
		 NSRect			 bounds = [self bounds];
		 NSDictionary	*attributes;
		 NSColor			*textColor;
		 
		 //Disable sub-pixel rendering.  It looks horrible with embossed text
		 CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], 0);
		 
		 //
		 textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.4];
		 attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			 textColor, NSForegroundColorAttributeName,
			 font, NSFontAttributeName, nil];
		 
		 [[self stringValue] drawInRect:NSOffsetRect(bounds, +2, +1) withAttributes:attributes];
		 
		 textColor = [NSColor colorWithCalibratedWhite:0.16 alpha:1.0];
		 attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			 textColor, NSForegroundColorAttributeName,
			 font, NSFontAttributeName,
			 nil];
		 
		 [[self stringValue] drawInRect:NSOffsetRect(bounds, +2, 0) withAttributes:attributes];
		 
		 
		 */
		
		
		xoffset += [self widthForSegment: i];
	}	
}

//- (BOOL) isFlipped
//{
//	return NO;
//}
//
//
//- (int) indexOfSelectedItem 
//{
//	return [super selectedSegment];
//}
//
//
//- (IBAction) selectTabFromSegmentedControl: (id) sender
//	/*" Sender is expected to be an NSSegmentedControl. "*/
//{
//	NSSegmentedControl* sc = sender;
//	[tabView selectTabViewItemAtIndex: [sc selectedSegment]];
//}

@end

