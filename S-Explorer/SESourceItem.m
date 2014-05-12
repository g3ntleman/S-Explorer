//
//  BRSourceItem.m
//  S-Explorer
//
//  Created by Dirk Theisen on 14.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SESourceItem.h"

NSString* SESourceItemChangedEditedStateNotification = @"SESourceItemChangedEditedState";

@implementation SESourceItem {
    NSString* _name;
    NSURL* _fileURL;
    NSMutableArray* _children; // SESourceItem objects
    __weak SESourceItem* _parent;
    NSInteger changeCount;
}

@synthesize content;


- (id) initWithFileURL: (NSURL*) aURL parent: (SESourceItem*) parentItem {
    if (self = [self init]) {
        NSParameterAssert(aURL != nil);
        NSNumber* typeNo;
        [aURL getResourceValue: &typeNo forKey: NSURLIsDirectoryKey error: NULL];
        _type = [typeNo boolValue] ? SESourceItemTypeFolder : SESourceItemTypeFile;

        _parent = parentItem;
        
        _fileURL = aURL;
        
        if (! parentItem && _type == SESourceItemTypeFolder) {
            // Assume root item
            _fileURL = [aURL fileReferenceURL];
        }
    }
    return self;
}

- (id) initWithFileURL: (NSURL*) aURL {
    return [self initWithFileURL: aURL parent: nil];
}

- (NSString*) name {
    if (! _name) {
        _name = [_fileURL lastPathComponent];
    }
    return _name;
}


- (IBAction) saveDocument: (id) sender {
    //if (self.isDocumentEdited) {
        [super saveDocument: sender];
    //}
}


- (NSTextStorage*) content {
    if (! content) {
        NSError* readError = nil;
        [self readFromURL: self.fileURL ofType: @"public.text" error:&readError];
        _lastError = readError;
    }
    return content;
}

- (void) enumerateAllUsingBlock: (void (^)(SESourceItem* item, BOOL *stop)) block stop: (BOOL*) stopPtr {
    block(self, stopPtr);
    
    for (SESourceItem* child in self.children) {
        if (*stopPtr) {
            break;
        }
        [child enumerateAllUsingBlock: block stop: stopPtr];
    }
}

//- (NSString*) relativePath {
//    if (_fileURL) {
//        return @"";
//    }
//    return [[_parent relativePath] stringByAppendingPathComponent: _pathComponent];
//}

- (void) enumerateAllUsingBlock: (void (^)(SESourceItem* item, BOOL *stop)) block {
    BOOL stop = NO;
    [self enumerateAllUsingBlock:block stop: &stop];
}

- (BOOL) isTextItem {
    
    if (_type == SESourceItemTypeFolder) {
        return NO;
    }
    
    BOOL result = YES;
    
    NSString *type;
    NSError *error;
    if ([self.fileURL getResourceValue:&type forKey:NSURLTypeIdentifierKey error:&error]) {
        result = ([[NSWorkspace sharedWorkspace] type:type conformsToType:@"public.text"]);
    }
    
    return result; // should we cache the result?
}

- (NSString*) displayName {
    return [self.fileURL lastPathComponent];
}

- (BOOL) readFromURL: (NSURL*) absoluteURL
              ofType: (NSString*) typeName
               error: (NSError**) outError {
    
    NSString* contentString = [NSString stringWithContentsOfURL:absoluteURL encoding:NSUTF8StringEncoding error: outError];
    if (contentString) {
        content = [[NSTextStorage alloc] initWithString: contentString];
    }
    self.fileType = typeName;
    return contentString != nil;
}

- (BOOL) writeToURL: (NSURL*) url ofType: (NSString*) typeName error: (NSError *__autoreleasing *) outError {
    BOOL success = [self.content.string writeToURL: url atomically: NO encoding: NSUTF8StringEncoding error: outError];
    return success;
}

- (SESourceItem*) childItemWithName: (NSString*) name {
    if ([name isEqualToString: @"/"]) {
        return self;
    }
    for (SESourceItem* child in self.children) {
        if ([child.name isEqualToString: name]) {
            return child;
        }
    }
    return nil;
}

- (SESourceItem*) childWithPath: (NSString*) aPath {
    NSArray* pathComponents = [aPath pathComponents];
    SESourceItem* current = self;
    for (NSString* name in pathComponents) {
        current = [current childItemWithName: name];
        if (! current) return nil;
    }
    return current;
}


/** 
  * Creates, caches, and returns the array of children SESourceItem objects.
  * Loads children incrementally. Returns nil for file items that cannot have children.
  **/
- (NSArray *)children {
    
    if (self.type != SESourceItemTypeFolder) {
        return nil; // Files cannot have children
    }
    
    if (_children == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];

        _children = [[NSMutableArray alloc] initWithCapacity: 10];
        
        for (NSURL* itemURL in [fileManager enumeratorAtURL: self.fileURL
                                 includingPropertiesForKeys: @[NSURLIsDirectoryKey]
                                                    options: NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                               errorHandler: ^BOOL(NSURL *url, NSError *error) {
                                                   NSLog(@"Error enumerating %@. Error %@", url, error);
                                                   return YES;
                                               }])
        {
            SESourceItem* item = [[[self class] alloc] initWithFileURL: itemURL parent: self];
            NSLog(@"item = %@", itemURL);
            [_children addObject: item];
        }
        
        _children = [_children copy]; // make immutable
    }
    return _children;
}


//- (NSString*) relativePath {
//    if (parent == nil) {
//        return @"";
//    }
//    
//    return path;
//}

///**
// * Returns the path relative to the root parent. For the root item, returns the empty string.
// */
//- (NSString*) longRelativePath {
//    if (! parent) {
//        return @"";
//    }
//    return [[parent longRelativePath] stringByAppendingPathComponent: path];
//}

//- (NSString*) absolutePath {
//    // If no parent, return path
//    if (parent == nil) {
//        return path;
//    }
//    
//    // recurse up the hierarchy, prepending each parent’s path
//    return [parent.absolutePath stringByAppendingPathComponent:path];
//}

- (NSURL*) fileURL {
    if (_fileURL) {
        return [_fileURL filePathURL];
    }
    NSURL* url = [[NSURL alloc] initWithString: _name relativeToURL: [self.parent fileURL]];
    return url;
}

- (void) setFileURL:(NSURL *)url {
    // File URLs cannot be changed. Create a new instance instead!
    NSParameterAssert([url isEqual: self.fileURL]);
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@ @ '%@'", [super description], self.fileURL];
}

//- (NSArray*) sortedItemsWithPathExtension: (NSString*) pathExtension {
//    NSMutableArray* result = [[NSMutableArray alloc] init];
//    [self enumerateAllUsingBlock:^(SESourceItem *item, BOOL *stop) {
//        if (! pathExtension || [item.relativePath.pathExtension compare: pathExtension options: NSCaseInsensitiveSearch] == NSOrderedSame) {
//            [result addObject: item];
//        }
//    }];
//    [result sortWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id obj1, id obj2) {
//        return [[obj1 relativePath] compare: [obj2 relativePath] options: NSCaseInsensitiveSearch];
//    }];
//    
//    return result;
//}

- (BOOL) isDocumentEdited {
    return changeCount != 0;
}

- (void) setChangeCount: (NSInteger) newCount {
    if (changeCount != newCount) {
        BOOL isDocumentEditedChanged = (changeCount == 0 || newCount == 0);
        changeCount = newCount;

        if (isDocumentEditedChanged) {
            [[NSNotificationCenter defaultCenter] postNotificationName: @"SESourceItemChangedEditedState" object: self];
        }
    }
}


- (void) updateChangeCount: (NSDocumentChangeType) change {
    if (change == NSChangeCleared) {
        [self setChangeCount: 0];
        return;
    }
    if (change == NSChangeDone || change == NSChangeRedone) {
        [self setChangeCount: changeCount+1];
        return;
    }
    
    if (change == NSChangeUndone) {
        [self setChangeCount: changeCount-1];
        return;
    }
}

@end

@implementation SESourceItem (PB)

- (NSArray*) writableTypesForPasteboard: (NSPasteboard*) pasteboard {
    return @[(NSString *)kPasteboardTypeFileURLPromise, NSPasteboardTypeString];
}


/* Returns the appropriate property list object for the provided type.  This will commonly be the NSData for that data type.  However, if this method returns either a string, or any other property-list type, the pasteboard will automatically convert these items to the correct NSData format required for the pasteboard.
 */
- (id) pasteboardPropertyListForType: (NSString*) pbType {
    
    if (pbType == NSPasteboardTypeString) {
        return self.fileURL.path;
    }
    //NSLog(@"pasteboardPropertyListForType %@ is %@", type, url);
    return self.fileURL;
}


@end