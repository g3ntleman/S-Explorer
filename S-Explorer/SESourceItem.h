//
//  BRSourceItem.h
//  S-Explorer
//
//  Created by Dirk Theisen on 14.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* SESourceItemChangedEditedStateNotification;

typedef enum {
    SESourceItemTypeUnknown = 0,
    SESourceItemTypeFile,
    SESourceItemTypeFolder
} SESourceItemType;

@interface SESourceItem : NSDocument

@property (nonatomic, readonly) BOOL isTextItem;
@property (nonatomic, weak, readonly) SESourceItem* parent;
@property (nonatomic, strong) NSTextStorage* content;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) SESourceItemType type;



@property (readonly) NSError* lastError;

- (id) initWithFileURL: (NSURL*) aURL;

- (SESourceItem*) childItemWithName: (NSString*) name;
- (SESourceItem*) childWithPath: (NSString*) path;

- (void) enumerateAllUsingBlock: (void (^)(SESourceItem* item, BOOL *stop)) block;

@end

@interface SESourceItem (PB) <NSPasteboardWriting>

@end
