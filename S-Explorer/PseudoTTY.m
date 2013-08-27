//
//  Created by Ingvar Nedrebo on Tue Mar 19 2002.
//

#import "PseudoTTY.h"
#import <util.h>
#include <sys/ioctl.h>
#include <unistd.h>

@implementation PseudoTTY {
    NSString * name;
    NSFileHandle * masterFH;
    NSFileHandle * slaveFH;
}

-(id) init {
    if (self = [super init]) {
        int masterfd, slavefd;
        char devname[64];
        if (openpty(&masterfd, &slavefd, devname, NULL, NULL) == -1) {
            [NSException raise:@"OpenPtyErrorException"
                        format:@"%s", strerror(errno)];
        }
        name = [[NSString alloc] initWithCString:devname encoding: NSASCIIStringEncoding];
        slaveFH = [[NSFileHandle alloc] initWithFileDescriptor:slavefd];
        masterFH = [[NSFileHandle alloc] initWithFileDescriptor:masterfd
                                                  closeOnDealloc:YES];

	if (setsid() < 0)
	    perror("setsid");
	
	if (ioctl(slavefd, TIOCSCTTY, NULL) < 0)
	    perror("setting control terminal");
    }
    return self;
}

-(NSString *)name {
    return name;
}

-(NSFileHandle *)masterFileHandle {
    return masterFH;
}

-(NSFileHandle *)slaveFileHandle {
   return slaveFH;
}

- (NSString*) description {
    return [NSString stringWithFormat: @"%@ %@", [super description], self.name];
}

- (void) dealloc {
    masterFH = nil;
    slaveFH = nil;
}

@end
