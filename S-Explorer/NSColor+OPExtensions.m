//
//  NSColor+OPExtensions.m
//  S-Explorer
//
//  Created by Dirk Theisen on 23.08.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import "NSColor+OPExtensions.h"

@implementation NSColor (OPExtensions)

+ (NSColor*) colorFromHexRGB: (NSString*) inColorString {
    NSParameterAssert(inColorString.length >= 6);
    
    char hexColorCString[9];
    [inColorString getBytes: hexColorCString maxLength: 8 usedLength: NULL encoding: NSASCIIStringEncoding options: NSStringEncodingConversionAllowLossy range:NSMakeRange(0, inColorString.length) remainingRange: NULL];
    hexColorCString[6] = 0; // temination
	long colorCode = strtol(hexColorCString, (char **)NULL, 16);
	
    unsigned char alphaByte = 255;
    
    if (inColorString.length > 6) {
        alphaByte = colorCode % 0xff;
        colorCode = colorCode >> 8;
    }
	unsigned char redByte	= (unsigned char) (colorCode >> 16);
	unsigned char greenByte = (unsigned char) (colorCode >> 8);
	unsigned char blueByte = (unsigned char) (colorCode);
    
	return [NSColor colorWithGenericRed: (float)redByte/0xff green:(float)greenByte/0xff blue:(float)blueByte/0xff alpha: alphaByte/0xff];
}


+ (NSColor *)colorWithGenericRed: (CGFloat) red green: (CGFloat) green blue: (CGFloat) blue alpha: (CGFloat) alpha {
	CGFloat comps[4] = {red, green, blue, alpha};
	return [NSColor colorWithColorSpace: [NSColorSpace sRGBColorSpace] components: comps count: 4];
}


@end
