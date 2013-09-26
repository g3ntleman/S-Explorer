//
//  BRSourceItem.h
//  S-Explorer
//
//  Created by Dirk Theisen on 14.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SESourceItem : NSDocument

@property (readonly) BOOL isTextItem;
@property (weak, readonly, nonatomic) SESourceItem* parent;
@property (strong, nonatomic) NSTextStorage* content;

@property (readonly) NSString* absolutePath;
@property (readonly) NSString* relativePath;
@property (readonly) NSString* longRelativePath;

@property (readonly) NSError* lastError;

- (id) initWithFileURL: (NSURL*) aURL;

- (SESourceItem*) childItemWithName: (NSString*) name;
- (SESourceItem*) childWithPath: (NSString*) path;

- (void) performBlock: (void (^)(SESourceItem* item)) block recursively: (BOOL) recurse;

@end

@interface SESourceItem (PB) <NSPasteboardWriting>

@end
