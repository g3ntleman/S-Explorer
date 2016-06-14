//
//  NSUserDefaults+OPMutability.m
//  S-Explorer
//
//  Created by Dirk Theisen on 12.06.16.
//  Copyright © 2016 Cocoanuts. All rights reserved.
//

#import "NSUserDefaults+OPMutability.h"

@interface OPUserDefaultsProxy : NSProxy {
    NSMutableDictionary* _dict;
}

@property (readonly) NSString* key;

- (id) initWithKey: (NSString*) key;

@end

@implementation NSUserDefaults (OPMutability)

- (NSMutableDictionary*) mutableDictionaryForKey: (NSString*) key {
    return (NSMutableDictionary*)[[OPUserDefaultsProxy alloc] initWithKey: key];
}

@end


@implementation OPUserDefaultsProxy

- (id) initWithKey: (NSString*) key {
    NSParameterAssert(key.length>0);
    _key = key;
    NSDictionary* d = [[NSUserDefaults standardUserDefaults] dictionaryForKey: key];
    if (! [d isKindOfClass: [NSDictionary class]]) {
        _dict = [[NSMutableDictionary alloc] init];
    } else {
        _dict = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (CFDictionaryRef)d, kCFPropertyListMutableContainers));
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget: _dict];
}

- (nullable NSMethodSignature*) methodSignatureForSelector: (SEL) sel {
    return [_dict methodSignatureForSelector: sel];
}


- (void) commitChanges {
    NSAssert(_dict, @"No dictionary set.");
    [[NSUserDefaults standardUserDefaults] setObject: _dict forKey: _key];
}

- (void)dealloc {
    [self commitChanges];
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@ %@", [super description], [_dict description]];
}

@end

@implementation NSMutableDictionary (OPMutability)

- (NSMutableDictionary*) mutableDictionaryForKey: (NSString*) key {
    NSMutableDictionary* result = [self objectForKey: key];
    if (! result) {
        result = [[NSMutableDictionary alloc] init];
        [self setObject: result forKey: key];
    } else {
        NSAssert([result isKindOfClass: [NSMutableDictionary class]], @"existing object not a mutable dictionary");
    }
    return result;
}

@end