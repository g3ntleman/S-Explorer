//
//  NSMutableAttributedString+OPConvenience.m
//  S-Explorer
//
//  Created by Dirk Theisen on 11.08.14.
//  Copyright (c) 2014 Cocoanuts. All rights reserved.
//

#import "NSMutableAttributedString+OPConvenience.h"

@implementation NSMutableAttributedString (OPConvenience)

- (void) setString: (NSString*) aString {
    [self replaceCharactersInRange: NSMakeRange(0, self.length) withString: aString];
}

@end
