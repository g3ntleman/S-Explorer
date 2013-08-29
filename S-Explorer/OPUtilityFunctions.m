//
//  OPUtilityFunctions.m
//  S-Explorer
//
//  Created by Dirk Theisen on 29.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "OPUtilityFunctions.h"

id <NSCopying> OPClone(id <NSCopying> obj) {
    NSData* tempData = [NSArchiver archivedDataWithRootObject: obj];
    id <NSCopying> clone = [NSUnarchiver unarchiveObjectWithData: tempData];
    
    return clone;
}