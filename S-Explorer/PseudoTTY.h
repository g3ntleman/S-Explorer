//
//  Created by Ingvar Nedrebo on Tue Mar 19 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PseudoTTY : NSObject


-(id)init;
-(NSString *)name;
-(NSFileHandle *)masterFileHandle;
-(NSFileHandle *)slaveFileHandle;

@end
