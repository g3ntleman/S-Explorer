//
//  BRSourceItem.m
//  Bracket
//
//  Created by Dirk Theisen on 14.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "BRSourceItem.h"

@implementation BRSourceItem {
    NSString* path;
    NSMutableArray* children;
    NSMutableString* changedContent;
}

static NSMutableArray *leafNode = nil;


@synthesize parent;
@synthesize content;

- (id) initWithPath: (NSString*) aPath parent: (BRSourceItem*) parentItem {

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


- (id) initWithFileURL: (NSURL*) aURL {
    return [self initWithPath: aURL.path parent: nil];
}

- (NSMutableString*) content {
    if (! content) {
        NSError* error = nil;
        content = [NSMutableString stringWithContentsOfFile: self.absolutePath encoding: NSUTF8StringEncoding error: &error];
    }
    
    return content;
}

- (void) contentDidChange {
    changedContent = self.content;
}

- (BOOL) saveContentWithError: (NSError**) errorPtr  {
    if (changedContent) {
        BOOL result = [changedContent writeToFile: self.absolutePath atomically: YES encoding: NSUTF8StringEncoding error: errorPtr];
        if (result) {
            content = changedContent;
            changedContent = nil;
        }
    }
    NSLog(@"Warning - igornig save to unchanged file %@", self.relativePath);
    return YES; // nothing to do.
}

- (BOOL) contentHasChanged {
    return changedContent != nil;
}


- (BRSourceItem*) childWithName: (NSString*) name {
    for (BRSourceItem* child in self.children) {
        if ([child.relativePath isEqualToString: name]) {
            return child;
        }
    }
    return nil;
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



@end