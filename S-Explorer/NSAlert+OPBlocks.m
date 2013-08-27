//
//  NSAlert+OPBlocks.m
//  S-Explorer
//
//  Created by Dirk Theisen on 13.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "NSAlert+OPBlocks.h"

static NSMutableArray *allBlockDelegateInstances = nil;

@interface OPAlertViewBlockDelegate : NSObject <NSAlertDelegate>
@property (nonatomic, copy) void (^completionBlock)(NSInteger);
@end

@implementation OPAlertViewBlockDelegate

@synthesize completionBlock = completionBlock_;

- (id)initWithCompletionBlock:(void (^)(NSInteger buttonIndex))completionBlock {
    if (self = [super init]) {
        self.completionBlock = completionBlock;
    }
    
    return self;
}

- (void)alertView:(NSAlert*) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex {
    self.completionBlock(buttonIndex);
    [allBlockDelegateInstances removeObject:self];
}

@end

@implementation NSAlert (OPBlocks)

- (void)runWithCompletion:(void (^)(NSInteger buttonIndex))completionBlock {
#ifndef __clang_analyzer__
    OPAlertViewBlockDelegate *blockDelegate = [[OPAlertViewBlockDelegate alloc] initWithCompletionBlock:completionBlock];
    
    if (!allBlockDelegateInstances) allBlockDelegateInstances = [[NSMutableArray alloc] init];
    [allBlockDelegateInstances addObject:blockDelegate];
    self.delegate = blockDelegate;
    [self runModal];
#endif
}

@end