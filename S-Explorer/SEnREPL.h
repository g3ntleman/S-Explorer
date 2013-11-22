//
//  SEREPL.h
//  S-Explorer
//
//  Created by Dirk Theisen on 10.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEnREPL : NSObject

@property (nonatomic, readonly) NSTask* task;

@property (nonatomic, strong) NSDictionary* settings;

@property (readonly, nonatomic) NSInteger port; // the network port on localhost, where clients can connect to

- (id) initWithSettings: (NSDictionary*) initialSettings;

- (void) startWithError: (NSError**) errorPtr;
- (void) stop;

@end
