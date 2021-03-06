//
//  BRSourceItem.h
//  S-Explorer
//
//  Created by Dirk Theisen on 14.06.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SESourceEditorController;

extern NSString* SESourceItemChangedEditedStateNotification;

typedef enum {
    SESourceItemTypeUnknown = 0,
    SESourceItemTypeFile,
    SESourceItemTypeFolder
} SESourceItemType;

@interface SESourceItem : NSDocument

@property (nonatomic, readonly) BOOL isTextItem;
@property (nonatomic, weak, readonly) SESourceItem* parent;
@property (nonatomic, strong) NSTextStorage* contents;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) SESourceItemType type;
@property (nonatomic, strong) IBOutlet SESourceEditorController* sourceEditorController;


@property (readonly) NSError* lastError;

//- (id) initWithFileURL: (NSURL*) aURL;
- (id) initWithContentsOfURL: (NSURL*) aURL parent: (SESourceItem*) parentItem ofType: (NSString*) typeName error: (NSError*__autoreleasing*) outError;

- (id) initWithContentsOfURL: (NSURL*) url ofType: (NSString*) typeName error: (NSError*__autoreleasing*) outError;


- (void) syncChildrenRecursive: (BOOL) recursive;

- (SESourceItem*) childWithPath: (NSString*) path;

- (void) enumerateAllUsingBlock: (void (^)(SESourceItem* item, BOOL *stop)) block;

- (void) open;
- (void) close;
- (BOOL) isOpen;

@end

@interface SESourceItem (PB) <NSPasteboardWriting>

@end

@interface NSArray (SEFind)

- (id) itemWithName: (NSString*) name;

@end
