//
//  Created by Ingvar Nedrebo on Tue Mar 19 2002.
//

#import "PseudoTTY.h"
#import <util.h>
#include <sys/ioctl.h>
#include <unistd.h>

@implementation PseudoTTY

@synthesize name;
@synthesize slaveFileHandle;
@synthesize masterFileHandle;

-(id)init {
    if (self = [super init]) {
        int masterfd, slavefd;
        char devname[1024];
        if (openpty(&masterfd, &slavefd, devname, NULL, NULL) == -1) {
            [NSException raise:@"OpenPtyErrorException"
                        format:@"%s", strerror(errno)];
        }
        devname[1023] = 0; // last resort terminate
        name = [[NSString alloc] initWithCString:devname encoding: NSASCIIStringEncoding];
        slaveFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:slavefd];
        masterFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:masterfd
                                                  closeOnDealloc:YES];

	if (setsid() < 0)
	    perror("setsid");
	
	if (ioctl(slavefd, TIOCSCTTY, NULL) < 0)
	    perror("setting control terminal");
    }
    return self;
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat: @"%@ %@", [super description], self.name];
}

- (void)dealloc {
    masterFileHandle = nil;
    slaveFileHandle = nil;
}

@end
