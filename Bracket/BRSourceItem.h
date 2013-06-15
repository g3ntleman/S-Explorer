//
//  BRSourceItem.h
//  Bracket
//
//  Created by Dirk Theisen on 14.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRSourceItem : NSObject
{
    NSString *path;
    NSMutableArray *children;
}

@property (weak, readonly) BRSourceItem* parent;

- (id)initWithPath:(NSString *)aPath;

- (NSInteger)numberOfChildren;// Returns -1 for leaf nodes
- (BRSourceItem *)childAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
- (NSString *)absolutePath;
- (NSString *)relativePath;

@end
