//
//  NSObject_OPImmutables.m
//  S-Explorer
//
//  Created by Dirk Theisen on 05.06.16.
//  Copyright © 2016 Cocoanuts. All rights reserved.
//

#import "NSObject+OPImmutables.h"

@implementation NSObject (NOPImmutables)

- (id) objectBySettingValue: (id) value
              forKeyinArray: (NSArray*) keys
                    atIndex: (NSUInteger) index {
    
    if (index == keys.count-1) {
        return [self objectBySettingValue: value forKey: keys[index]];
    }
    id inner = [self valueForKey: keys[index]];
    if (! inner) {
        inner = @{}; // assume dictionary, if unknown
    }
    
    id object = [inner objectBySettingValue: value forKeyinArray: keys atIndex: index+1];
    
    return [self objectBySettingValue: object forKey: keys[index]];
}


- (id) objectBySettingValue: (id) value forKeyPath: (NSString*) keyPath {
    
    NSArray* components = [keyPath componentsSeparatedByString: @"/"];
    
    return [self objectBySettingValue: value forKeyinArray: components atIndex: 0];
}

- (id) objectBySettingValue: (id) value forKey: (NSString*) key {
    return self; //throw?
}

@end

@implementation NSDictionary (OPImmutables)

- (id) objectBySettingValue: (id) value forKey: (NSString*) key {
    NSMutableDictionary* copy = [self mutableCopy];
    [copy setObject: value forKey: key];
    return copy;
}

@end

@implementation NSUserDefaults (OPImmutables)

- (void) setObject: (id) value forKeyPath: (NSString*) keyPath {
    
    NSParameterAssert(keyPath.length > 0);
    NSArray* components = [keyPath componentsSeparatedByString: @"/"];
    
    if (components.count > 1) {
        id firstValue = [self objectForKey: components.firstObject];
        
        firstValue = [firstValue objectBySettingValue: value
                                        forKeyinArray: components
                                              atIndex: 1];
        
        [self setObject: firstValue forKey: components.firstObject];
    } else {
        [self setObject: value forKey: keyPath];
    }
}

@end
