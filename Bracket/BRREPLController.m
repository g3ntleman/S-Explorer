//
//  BRTerminalController.m
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "BRREPLController.h"
#import "BRREPLView.h"

@implementation BRREPLController {

    NSUInteger commandOffset; // where the current command starts
}

static NSData* lineFeedData = nil;

+ (void) load {
    lineFeedData = [NSData dataWithBytes: "\n" length: 1];
}

- (id) init {
    if (self = [super init]) {
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {

    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    
}





- (void) taskOutputReceived: (NSNotification*) n {
    NSFileHandle* filehandle = n.object;
    //NSData* data = filehandle.availableData;
    NSData* data = n.userInfo[NSFileHandleNotificationDataItem];
    NSString* string = [[NSString alloc] initWithData: data encoding: NSISOLatin1StringEncoding];
    
    
    [self.replView appendString: string];
    
    [filehandle readInBackgroundAndNotify];
}

- (void) commitCommand: (NSString*) commandString {
    
    //NSData* stringData = [commandString dataUsingEncoding: NSISOLatin1StringEncoding];
}

//- (void) runCommand: (NSString*) command
//      withArguments: (NSArray*) arguments
//              error: (NSError**) errorPtr {
//    
//    NSAssert(! _task.isRunning, @"There is already a task (%@) running!", _task);
//    
//    command = [command stringByResolvingSymlinksInPath];
//
//    if (! [[NSFileManager defaultManager] isExecutableFileAtPath:command]) {
//        if (errorPtr) {
//            *errorPtr = [NSError errorWithDomain: @"org.cocoanuts.bracket" code: 404
//                                        userInfo: @{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"No Executable file at '%@'", command]}];
//        }
//        return;
//    }
//    
//
//}

@end
