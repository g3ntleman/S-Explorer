//
//  NSDictionary+OPImmutablility.m
//  S-Explorer
//
//  Created by Dirk Theisen on 17.06.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import "NSDictionary+OPImmutablility.h"

@implementation NSDictionary (OPImmutablility)

- (id) dictionaryByRemovingObjectForKey: (id<NSCopying>) key {
    NSMutableDictionary * dictionary = [self mutableCopy];
    [dictionary removeObjectForKey: key];
    return [dictionary copy];
}

-(id) dictionaryBySettingObject: (id) value forKey: (id<NSCopying>) key {
    NSMutableDictionary * dictionary = [self mutableCopy];
    [dictionary setObject: value forKey: key];
    return [dictionary copy];
}

- (id) dictionaryByAddingEntriesFromDictionary: (NSDictionary*) dictionary {
    NSMutableDictionary* result = [self mutableCopy];
    [result addEntriesFromDictionary: dictionary];
    return result;
}


@end
