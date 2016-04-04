//
//  SETarget.h
//  S-Explorer
//
//  Created by Dirk Theisen on 21.03.16.
//  Copyright © 2016 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SETarget;

typedef void (^SETargetCompletionBlock)(SETarget* target, NSError* error);

@interface SETarget : NSObject

@property (nonatomic, readonly) NSTask* task;

@property (nonatomic, strong) NSDictionary* settings;

@property (readonly, nonatomic) NSInteger port; // the network port on localhost, where clients can connect to

- (void) startWithCompletionBlock: (SETargetCompletionBlock) block;
- (void) stop;

@end
