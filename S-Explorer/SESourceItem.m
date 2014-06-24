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
    NSMutableArray* _children; // SESourceItem objects
    __weak SESourceItem* _parent;
    NSInteger changeCount;
    BOOL changeCountValid;
}

@synthesize content;

- (id) init {
    if (self = [super init]) {
        changeCountValid = YES;
        //[self.undoManager setGroupsByEvent: NO];
    }
    return self;
}

- (id) initWithFileURL: (NSURL*) aURL parent: (SESourceItem*) parentItem {
    NSError* error = nil;
    if (self = [self init]) {
        NSParameterAssert(aURL != nil);
        NSNumber* typeNo;
        [aURL getResourceValue: &typeNo forKey: NSURLIsDirectoryKey error: &error];
        _type = [typeNo boolValue] ? SESourceItemTypeFolder : SESourceItemTypeFile;
        _parent = parentItem;

        self.fileURL = aURL;
        if (_type == SESourceItemTypeFile) {
            NSString* theType;
            [aURL getResourceValue:&theType forKey:NSURLTypeIdentifierKey error:&error];
            self.fileType = theType;
        }
        
        NSDate* modDate = nil;
        [aURL getResourceValue: &modDate forKey: NSURLContentModificationDateKey error: &error];

        self.fileModificationDate = modDate;
        
        if (! parentItem && _type == SESourceItemTypeFolder) {
            // Assume root item
            self.fileURL = [aURL fileReferenceURL];
        }
        NSAssert(self.fileModificationDate, @"No file mod date set after init.");
    }
    return self;
}

- (id) initWithFileURL: (NSURL*) aURL {
    return [self initWithFileURL: aURL parent: nil];
}

- (NSString*) name {
    if (! _name) {
        _name = [self.fileURL lastPathComponent];
    }
    return _name;
}

//+ (BOOL) canConcurrentlyReadDocumentsOfType: (NSString*) typeName {
//    return NO;
//}


- (IBAction) saveDocument: (id) sender {
    if (self.isDocumentEdited) {
        [super saveDocument: sender];
        NSAssert(self.fileModificationDate, @"No file mod date set after save.");
    }
}

//
//- (void) saveDocumentWithDelegate: delegate didSaveSelector: (SEL) selector contextInfo: (void*) info {
//    if (self.fileURL != nil) {
////        for (id editor in [_activeEditors copy])
////            [editor commitEditing];
//        
//        // Check if file has been changed by another process
//        NSFileManager * fileManager = [NSFileManager defaultManager];
//        NSString * path = [_fileURL path];
//        NSDictionary * attributes = [fileManager attributesOfItemAtPath: path error: NULL];
//        NSDate * dateModified = [attributes objectForKey:NSFileModificationDate];
//        if (attributes != nil && ![dateModified isEqualToDate: self.fileModificationDate]) {
//            int result = NSRunAlertPanel([self displayName],
//                                         @"Another user or process has changed this document's file on disk.\n\nIf you save now, those changes will be lost. Save anyway?",
//                                         @"Don't Save", @"Save", nil);
//            if (result == NSAlertDefaultReturn) {
//                // The user canceled the save operation.
//                if ([delegate respondsToSelector:selector])
//                {
//                    void (*delegateMethod)(id, SEL, id, BOOL, void *);
//                    delegateMethod = (void (*)(id, SEL, id, BOOL, void *))[delegate methodForSelector:selector];
//                    delegateMethod(delegate, selector, self, NO, info);
//                }
//                return;
//            }
//        }
//        
//        [self saveToURL: self.fileURL
//                 ofType: self.fileType
//       forSaveOperation: NSSaveOperation
//               delegate: delegate
//        didSaveSelector: selector
//            contextInfo: info];
//    } else {
//        [self runModalSavePanelForSaveOperation:NSSaveOperation
//                                       delegate:delegate
//                                didSaveSelector:selector
//                                    contextInfo:info];
//    }
//}

- (NSTextStorage*) content {
    if (! content) {
        NSError* readError = nil;
        [self readFromURL: self.fileURL ofType: self.fileType error: &readError];
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

//- (BOOL) keepBackupFile {
//    return NO;
//}
//
//- (NSURL *)backupFileURL {
//    return nil;
//}

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
    //self.fileType = typeName;
    return contentString != nil;
}

- (BOOL) writeToURL: (NSURL*) url ofType: (NSString*) typeName error: (NSError *__autoreleasing *) outError {
    BOOL success = [self.content.string writeToURL: url atomically: NO encoding: NSUTF8StringEncoding error: outError];
    if (success) {
        NSError* error2 = nil;
        NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: url.path error: &error2];
        if (error2) {
            if (outError) *outError = error2;
            return NO;
        }
        if (attributes) {
            self.fileModificationDate = attributes[NSFileModificationDate];
        }
    }
    return success;
}

/**
 * Primitive. Does not automatically sync.
 */
- (SESourceItem*) childItemWithName: (NSString*) name {
    if (name.length == 0 || [name isEqualToString: @"/"]) {
        return self;
    }
    for (SESourceItem* child in _children) {
        if ([child.name isEqualToString: name]) {
            return child;
        }
    }
    return nil;
}

- (SESourceItem*) childWithPath: (NSString*) aPath {
    if (_children == nil) {
        [self syncChildren];
    }
    NSArray* pathComponents = [aPath pathComponents];
    SESourceItem* current = self;
    for (NSString* name in pathComponents) {
        current = [current childItemWithName: name];
        if (! current) return nil;
    }
    return current;
}

/**
 * Syncs the children array with the file system. Call this whenever the file system has changed, so the documents can reflect that.
 */
- (void) syncChildren {
    
    if (self.type != SESourceItemTypeFolder) {
        return; // Files cannot have children
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSMutableArray* newChildren = [[NSMutableArray alloc] initWithCapacity: _children.count];
    
    for (NSURL* itemURL in [fileManager enumeratorAtURL: self.fileURL
                             includingPropertiesForKeys: @[NSURLIsDirectoryKey]
                                                options: NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                           errorHandler: ^BOOL(NSURL *url, NSError *error) {
                                               NSLog(@"Error enumerating %@. Error %@", url, error);
                                               return YES;
                                           }])
    {
        SESourceItem* item =  [self childItemWithName: [itemURL lastPathComponent]];
        if (! item) {
            item = [[[self class] alloc] initWithFileURL: itemURL parent: self];
        }
        [newChildren addObject: item];
    }
    
    // Detect all documents that are no longer a child:
    NSMutableSet* orphanedChildren = [NSMutableSet setWithArray: _children];
    for (SESourceItem* child in newChildren) {
        [orphanedChildren removeObject: child];
    }
    // CLose any orphaned childen:
    for (SESourceItem* orphanedChild in orphanedChildren) {
        [orphanedChild close];
    }
    
    _children = [newChildren copy]; // make immutable
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
        [self syncChildren];
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

//- (NSURL*) fileURL {
//    if (! _fileURL) {
//        //    if (_fileURL) {
//        //        return [_fileURL filePathURL];
//        //    }
//        if (_name.length && self.parent.fileURL) {
//            _fileURL = [[NSURL alloc] initWithString: _name relativeToURL: self.parent.fileURL];
//        }
//    }
//    return _fileURL;
//}



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
    return changeCount != 0 || ! changeCountValid;
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
        changeCountValid = YES;
        [self setChangeCount: 0];
        return;
    }
    if (changeCountValid) {
        if (change == NSChangeDone) {
            if (changeCount >= 0) {
                [self setChangeCount: changeCount+1];
            } else {
                // User forked prior to save point, stop tracking until next save:
                changeCountValid = NO;
            }
        }
        
        if (change == NSChangeRedone) {
            [self setChangeCount: changeCount+1];
            return;
        }
        
        if (change == NSChangeUndone) {
            [self setChangeCount: changeCount-1];
            return;
        }
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