//
//  SETarget.m
//  S-Explorer
//
//  Created by Dirk Theisen on 21.03.16.
//  Copyright © 2016 Cocoanuts. All rights reserved.
//

#import "SETarget.h"
#import "PseudoTTY.h"

@interface SETarget ()

@property (strong, nonatomic) SETargetCompletionBlock completionBlock;
@property (strong, nonatomic) PseudoTTY* tty;

@end

#import <sys/socket.h>
#import <netinet/in.h>
#import <net/if.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <sys/ioctl.h>


@implementation SETarget

- (id) initWithSettings: (NSDictionary*) initialSettings {
    if (self = [self init]) {
        self.settings = initialSettings;
    }
    return self;
}

- (void) dealloc {
    [self stop];
}

- (NSString*) debugDescription {
    return [NSString stringWithFormat: @"%@ %@, listening on port %ld", [super debugDescription], self.task, self.port];
}


/**
 * Starts the REPL task. A previous task is terminated.
 **/
- (void) startWithCompletionBlock: (SETargetCompletionBlock) block {
    
    // Stop a running task if neccessary:
    [self stop];
    
    _completionBlock = block;
    _task = [[NSTask alloc] init];
    
    //NSError* error = nil;
    NSMutableArray* commandArguments = [_settings[@"RuntimeArguments"] mutableCopy];
    
    NSString* workingDirectory = _settings[@"WorkingDirectory"];
    
//    NSString* sourceFile = _settings[@"StartupSource"];
//    if (sourceFile.length) {
//        [commandArguments addObject: [NSString stringWithFormat: @"-l%@", sourceFile]];
//    }
//    
//    NSString* expression = _settings[@"StartupExpression"];
//    if (expression.length) {
//        [commandArguments addObject: [NSString stringWithFormat: @"-e%@", expression]];
//    }
    
    //    int port = OPGetUnusedSocketPort();
    //    port = OPGetUnusedSocketPort();
    //    [commandArguments addObject: [NSString stringWithFormat: @":port %d", port]];
    
    
    //    NSString* portFormat = _settings[@"RuntimePortArgumentFormat"];
    //    if (portFormat.length) {
    //        [commandArguments addObjectsFromArray: [[NSString stringWithFormat: portFormat, @(_port)] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    //    }
    
    NSString* tool = _settings[@"RuntimeTool"];
    
    if (! [[NSFileManager defaultManager] isExecutableFileAtPath: tool]) {
        _completionBlock(self, [NSError errorWithDomain: @"org.cocoanuts.s-explorer"
                                                   code: 404
                                               userInfo: @{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"No Executable file at '%@'", tool]}]);
        return;
    }
    
    _task.launchPath = tool;
    _task.currentDirectoryPath = workingDirectory;
    
    NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    if (_settings[@"Environment"]) {
        [environment addEntriesFromDictionary: _settings[@"Environment"]];
    }
    [environment setObject: @"YES" forKey: @"NSUnbufferedIO"];
    [environment setObject: @"en_US-iso8859-1" forKey: @"LANG"];
    
    [_task setEnvironment: environment];
    [_task setArguments: commandArguments];
    
    _task.terminationHandler =  ^void (NSTask* task) {
        NSLog(@"REPL Task %@ Terminated with return code %d", task, task.terminationStatus);
        if (block) {
            if (task.terminationStatus != 0) {
                NSError* error = [NSError errorWithDomain: @"NSTask" code: task.terminationStatus
                                                 userInfo: @{@"reason": @(task.terminationReason)}];
                block(nil, error);
            }
            _task = nil; // break retain cycle
            _completionBlock = NULL;
        }
    };
    
    NSLog(@"Launching '%@' with %@: %@", _task.launchPath, _task.arguments, _task);
    
    
    self.tty = [[PseudoTTY alloc] init];
    
    [_task setStandardInput: [self.tty slaveFileHandle]];
    [_task setStandardOutput: [self.tty slaveFileHandle]];
    [_task setStandardError: [self.tty slaveFileHandle]];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskOutputReceived:)
                                                 name: NSFileHandleReadCompletionNotification
                                               object: self.tty.masterFileHandle];
    
    [[self.tty masterFileHandle] readInBackgroundAndNotify];
    
    [_task launch];
    
    
    //
    //    NSURL* portFileURL = [[NSURL fileURLWithPath: workingDirectory] URLByAppendingPathComponent:@".nrepl-port"];
    //    self.watcher = [LVPathWatcher watcherFor: portFileURL handler: ^{
    //
    //        NSString* portString = [NSString stringWithContentsOfURL: portFileURL encoding: NSASCIIStringEncoding error: NULL];
    //        if (portString.length) {
    //            _port = [portString integerValue];
    //            _completionBlock(self, nil); // nRepl was successfully started
    //        } else {
    //            _completionBlock(self, [NSError errorWithDomain: @"org.cocoanuts.s-explorer"
    //                                                       code: 404
    //                                                   userInfo: @{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"No nRepl port file found at '%@'", portFileURL]}]);
    //        }
    //        self.watcher = nil;
    //        
    //    }];
    
    
}


- (void) stop {
    if (self.task.isRunning) {
        NSLog(@"Terminating REPL Server Task.");
        
        [self.task terminate];
        
        _task = nil;
    }
}

@end
