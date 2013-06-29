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

- (BOOL) contentHasChanged {
    return changedContent != nil;
}

- (BOOL) saveContentWithError: (NSError**) errorPtr  {
    if (changedContent) {
        BOOL result = [changedContent writeToFile: self.absolutePath atomically: YES encoding: NSUTF8StringEncoding error: errorPtr];
        if (result) {
            content = changedContent;
            changedContent = nil;
        }
        return result;
    }
    NSLog(@"Warning - igornig save to unchanged file %@", self.relativePath);
    return YES; // nothing to do.
}

- (BOOL) revertContent {
    if (content) {
        content = nil;
        changedContent = nil;
        return YES;
    }
    return NO;
}


- (BRSourceItem*) childWithName: (NSString*) name {
    for (BRSourceItem* child in self.children) {
        if ([child.relativePath isEqualToString: name]) {
            return child;
        }
    }
    return nil;
}

- (BRSourceItem*) childWithPath: (NSString*) aPath {
    NSArray* pathComponents = [aPath pathComponents];
    BRSourceItem* current = self;
    for (NSString* name in pathComponents) {
        current = [current childWithName: name];
        if (! current) return nil;
    }
    return current;
}


// Creates, caches, and returns the array of children
// Loads children incrementally
- (NSArray *)children {
    
    if (children == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString* fullPath = self.absolutePath;
        BOOL isDir, valid;
        
        valid = [fileManager fileExistsAtPath: fullPath isDirectory: &isDir];
        
        if (valid && isDir) {
            NSArray *array = [fileManager contentsOfDirectoryAtPath: fullPath error:NULL];
                        
            children = [[NSMutableArray alloc] initWithCapacity: array.count];
            
            for (NSString* childPath in array) {
                if (! [childPath hasPrefix: @"."]) {
                    BRSourceItem* newChild = [[[self class] alloc] initWithPath: childPath parent: self];
                    [children addObject: newChild];
                }
            }
        } else {
            children = leafNode;
        }
        children = [children copy];
    }
    return children;
}


- (NSString*) relativePath {
    if (parent == nil) {
        return @"";
    }
    
    return path;
}

/**
 * Returns the path relative to the root parent. For the root item, returns the empty string.
 */
- (NSString*) longRelativePath {
    if (! parent) {
        return @"";
    }
    return [[parent longRelativePath] stringByAppendingPathComponent: path];
}

- (NSString*) absolutePath {
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

@implementation BRSourceItem (PB)

- (NSArray*) writableTypesForPasteboard: (NSPasteboard*) pasteboard {
    return @[(NSString *)kPasteboardTypeFileURLPromise, NSPasteboardTypeString];
}


/* Returns the appropriate property list object for the provided type.  This will commonly be the NSData for that data type.  However, if this method returns either a string, or any other property-list type, the pasteboard will automatically convert these items to the correct NSData format required for the pasteboard.
 */
- (id) pasteboardPropertyListForType: (NSString*) type {
    
    if (type == NSPasteboardTypeString) {
        return self.absolutePath;
    }
    NSURL* url = [NSURL fileURLWithPath: self.absolutePath];
    //NSLog(@"pasteboardPropertyListForType %@ is %@", type, url);
    return url.absoluteString;
}


@end