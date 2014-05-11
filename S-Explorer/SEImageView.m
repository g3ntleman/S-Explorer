//
//  SEImageView.m
//  S-Explorer
//
//  Created by Dirk Theisen on 11.05.14.
//  Copyright (c) 2014 Cocoanuts. All rights reserved.
//

#import "SEImageView.h"
#import "OPImageTinting.h"

@implementation SEImageView {
    NSImage* _originalImage;
}

- (BOOL) isHighlighted {
    return _originalImage != nil;
}

- (void) setImage:(NSImage *)newImage {
    [super setImage: newImage];
    _originalImage = nil;
}

- (void) setHighlighted: (BOOL) highlighted {
    if (self.isHighlighted != highlighted) {
        if (highlighted) {
            _originalImage = self.image;
            [super setImage: [self.image imageByTintingWithColor: [NSColor colorWithWhite: 0.0 alpha:0.33]]];
        } else {
            [super setImage: _originalImage];
            _originalImage = nil;
        }
    }
}

@end
