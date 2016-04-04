//
//  OPUtilityFunctions.h
//  S-Explorer
//
//  Created by Dirk Theisen on 29.08.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Returns a copy of the given object by archiving and then ∫unarchiving it.
 */
id <NSCopying> OPClone(id <NSCopying> obj);