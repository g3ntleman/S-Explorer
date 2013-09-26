//
//  OPCharFilterFormatter.h for firect use in IB, subclass!
//
//  Created by Dirk Theisen on Mon Mar 24 2003.
//  Copyright (c) 2003 Objectpark Software. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface OPCharFilterFormatter : NSFormatter {

}

+ (NSCharacterSet*) invalidCharacterSet;
+ (BOOL) stripSurroundingSpaces;

@end


@interface OPDigitFormatter : OPCharFilterFormatter

@end

