//
//  BRSourceItem.h
//  S-Explorer
//
//  Created by Dirk Theisen on 14.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SESourceItem : NSObject 

@property (readonly) BOOL isTextItem;
@property (weak, readonly) SESourceItem* parent;
@property (weak, nonatomic) NSMutableString* content;

@property (readonly) NSString* absolutePath;
@property (readonly) NSString* relativePath;
@property (readonly) NSString* longRelativePath;

- (id) initWithFileURL: (NSURL*) aURL;

- (SESourceItem*) childWithName: (NSString*) name;
- (SESourceItem*) childWithPath: (NSString*) path;

- (BOOL) contentHasChanged;
- (BOOL) saveContentWithError: (NSError**) errorPtr;
- (void) contentDidChange;
- (BOOL) revertContent;

@end

@interface SESourceItem (PB) <NSPasteboardWriting>

@end
