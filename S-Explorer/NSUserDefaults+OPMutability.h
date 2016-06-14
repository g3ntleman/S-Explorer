//
//  NSUserDefaults+OPMutability.h
//  S-Explorer
//
//  Created by Dirk Theisen on 12.06.16.
//  Copyright © 2016 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (OPMutability)

- (NSMutableDictionary*) mutableDictionaryForKey: (NSString*) key;

@end

@interface NSMutableDictionary (OPMutability)

- (NSMutableDictionary*) mutableDictionaryForKey: (NSString*) key;

@end