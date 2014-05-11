//
//  OPImageTinting.m
//  //  Spring
//
//  Created by Dirk Theisen on 27.08.08.
//  Copyright 2008 Objectpark Software GbR. All rights reserved.
//

#import "OPImageTinting.h"


@implementation NSImage (OPImageTinting)

- (NSImage*) imageByTintingWithColor:(NSColor*) tint {
	return [self imageByTintingWithColor: tint operation:NSCompositeSourceAtop];
}

/*
 * This method is the whole point of this exercise.  It creates a new image, draws the original image
 * into it, composites  the tint color over it with the given  NSCompositingOperation value, and 
 * returns the resulting image.
 */
- (NSImage*) imageByTintingWithColor: (NSColor*) tint operation: (NSCompositingOperation) op {
    
	NSSize size = [self size];
	NSRect imageBounds = NSMakeRect(0, 0, size.width, size.height);
	NSImage* newImage = [[NSImage alloc] initWithSize: size];  //  get a new image, the same size as this one
    
	[newImage lockFocus];   // Draw on the new Image.
	[self compositeToPoint: NSZeroPoint operation:NSCompositeSourceOver];  // copy our existing contents.
	[tint set];  // make sure the color has an alpha component, or we'll get a solid rectangle
	NSRectFillUsingOperation(imageBounds, op); // start drawing on the new image.
	[newImage unlockFocus];   //  Have to balance the -lockFocus/-unlockFocus calls.
	return newImage;
}

@end


