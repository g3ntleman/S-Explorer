//
//  BRSourceItem.h
//  Bracket
//
//  Created by Dirk Theisen on 14.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRSourceItem : NSObject


@property (weak, readonly) BRSourceItem* parent;
@property (weak, nonatomic) NSMutableString* content;

@property (readonly) NSString* absolutePath;
@property (readonly) NSString* relativePath;

- (id) initWithFileURL: (NSURL*) aURL;

- (BRSourceItem*) childWithName: (NSString*) name;

- (BOOL) contentHasChanged;
- (BOOL) saveContentWithError: (NSError**) errorPtr;
- (void) contentDidChange;

@end
