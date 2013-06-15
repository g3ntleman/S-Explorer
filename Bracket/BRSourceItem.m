//
//  BRSourceItem.m
//  Bracket
//
//  Created by Dirk Theisen on 14.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "BRSourceItem.h"

@implementation BRSourceItem

static NSMutableArray *leafNode = nil;


@synthesize parent;

- (id)initWithPath: (NSString*) aPath parent: (BRSourceItem*) parentItem {

    if (self = [self init]) {
        if (parentItem) {
            path = [[aPath lastPathComponent] copy];
            parent = parentItem;
        } else {
            path = aPath;
        }
    }
    return self;
}


- (id)initWithPath: (NSString*) aPath {
    return [self initWithPath: aPath parent: nil];
}


// Creates, caches, and returns the array of children
// Loads children incrementally
- (NSArray *)children {
    
    if (children == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fullPath = [self absolutePath];
        BOOL isDir, valid;
        
        valid = [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        
        if (valid && isDir) {
            NSArray *array = [fileManager contentsOfDirectoryAtPath:fullPath error:NULL];
                        
            NSUInteger numChildren = array.count;
            children = [[NSMutableArray alloc] initWithCapacity:numChildren];
            
            for (NSString* childPath in array) {
                BRSourceItem* newChild = [[[self class] alloc] initWithPath: childPath parent: self];
                [children addObject: newChild];
            }
        } else {
            children = leafNode;
        }
        children = [children copy];
    }
    return children;
}


- (NSString *)relativePath {
    if (parent == nil) {
        return [path lastPathComponent];
    }
    
    return path;
}


- (NSString *)absolutePath {
    // If no parent, return path
    if (parent == nil) {
        return path;
    }
    
    // recurse up the hierarchy, prepending each parent’s path
    return [parent.absolutePath stringByAppendingPathComponent:path];
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@ @ '%@'", [super description], self.absolutePath];
}


- (BRSourceItem*) childAtIndex: (NSUInteger) n {
    return [self children][n];
}


- (NSInteger)numberOfChildren {
    NSArray *tmp = [self children];
    return (tmp == leafNode) ? (-1) : [tmp count];
}

@end