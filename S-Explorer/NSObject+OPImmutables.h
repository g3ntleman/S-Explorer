//
//  NSObject_OPImmutables.h
//  S-Explorer
//
//  Created by Dirk Theisen on 05.06.16.
//  Copyright © 2016 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (OPImmutables)

- (id) objectBySettingValue: (id) value forKey: (NSString*) key;
- (id) objectBySettingValue: (id) value forKeyPath: (NSString*) keyPath;

@end
