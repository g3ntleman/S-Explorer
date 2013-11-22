//
//  NSDictionary+OPImmutablility.h
//  S-Explorer
//
//  Created by Dirk Theisen on 17.06.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (OPImmutablility)

- (id) dictionaryByRemovingObjectForKey: (id<NSCopying>) key;

- (id) dictionaryBySettingObject: (id) value forKey: (id<NSCopying>) key;

- (id) dictionaryByAddingEntriesFromDictionary: (NSDictionary*) dictionary;

@end
