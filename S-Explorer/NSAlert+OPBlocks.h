//
//  NSAlert+OPBlocks.h
//  S-Explorer
//
//  Created by Dirk Theisen on 13.05.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAlert (OPBlocks)

- (void) runWithCompletion:(void (^)(NSInteger buttonIndex))completionBlock;


@end
