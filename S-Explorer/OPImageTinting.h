//
//  OPImageTinting.h
//  //  Spring
//
//  Created by Dirk Theisen on 27.08.08.
//  Copyright 2008 Objectpark Software GbR. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (OPImageTinting)

- (NSImage *) imageByTintingWithColor:(NSColor *) tint;

- (NSImage *) imageByTintingWithColor:(NSColor *) tint operation:(NSCompositingOperation) op;

@end

