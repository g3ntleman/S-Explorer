//
//  Created by Ingvar Nedrebo on Tue Mar 19 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PseudoTTY : NSObject

@property (readonly) NSFileHandle* masterFileHandle;
@property (readonly) NSFileHandle* slaveFileHandle;
@property (readonly) NSString* name;

-(id)init; // designated initializer

@end
