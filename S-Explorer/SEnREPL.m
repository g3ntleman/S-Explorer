//
//  SEREPL.m
//  S-Explorer
//
//  Created by Dirk Theisen on 10.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEnREPL.h"
#import "LVPathWatcher.h"

@interface SEnREPL ()

@property (strong, nonatomic) SEnREPLCompletionBlock completionBlock;
@property (strong, nonatomic) LVPathWatcher* watcher;

@end

@implementation SEnREPL



- (id) initWithSettings: (NSDictionary*) initialSettings {
    if (self = [self init]) {
        self.settings = initialSettings;
    }
    return self;
}

- (void) dealloc {
    [self stop];
}

- (void) stop {
    if (self.task.isRunning) {
        NSLog(@"Terminating REPL Server Task.");
        
        [self.task terminate];

        _task = nil;
    }
}

- (void) taskOutputReceived: (NSNotification*) n {
    
    NSFileHandle* filehandle = n.object;
    //NSData* data = filehandle.availableData;
    NSData* data = n.userInfo[NSFileHandleNotificationDataItem];
    
    if (data.length) {
        //NSError* error = nil;
        
        NSString* string = [[NSString alloc] initWithData: data encoding: NSISOLatin1StringEncoding];
        
        NSLog(@"-> %@", string);
        
        [filehandle readInBackgroundAndNotify];
    } else {
        if (! self.port) {
            NSLog(@"\n--> Process exited with exit code %d.\n", self.task.terminationStatus);
        }
    }
}

/**
 * Starts the REPL task. A previous task is terminated.
 **/
- (void) startWithCompletionBlock: (SEnREPLCompletionBlock) block {
    
    // Stop a running task if neccessary:
    [self stop];
    
    _completionBlock = block;
    _task = [[NSTask alloc] init];

    //NSError* error = nil;
    NSMutableArray* commandArguments = [_settings[@"RuntimeArguments"] mutableCopy];
    
    NSString* workingDirectory = _settings[@"WorkingDirectory"];
    
    NSString* sourceFile = _settings[@"StartupSource"];
    if (sourceFile.length) {
        [commandArguments addObject: [NSString stringWithFormat: @"-l%@", sourceFile]];
    }
    
    NSString* expression = _settings[@"StartupExpression"];
    if (expression.length) {
        [commandArguments addObject: [NSString stringWithFormat: @"-e%@", expression]];
    }
    
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
    [environment setObject: @"YES" forKey: @"NSUnbufferedIO"];
    [environment setObject: @"en_US-iso8859-1" forKey: @"LANG"];
    
    [_task setEnvironment: environment];
    [_task setArguments: commandArguments];
    
    
    _task.terminationHandler =  ^void (NSTask* task) {
        NSLog(@"REPL Task Terminated with return code %d", task.terminationStatus);
//        if (task.terminationStatus == 1) {
//            //NSLog(@"Port %ld seems in use. Restarting...", this.port);
//            [this stop];
//            [this startWithCompletionBlock: this.completionBlock];
//            return;
//        }
    };
    
    NSLog(@"Launching '%@' with %@: %@", _task.launchPath, _task.arguments, _task);
    
    
    NSURL* portFileURL = [[NSURL fileURLWithPath: workingDirectory] URLByAppendingPathComponent:@".nrepl-port"];
    self.watcher = [LVPathWatcher watcherFor: portFileURL handler: ^{
        
        NSString* portString = [NSString stringWithContentsOfURL: portFileURL encoding: NSASCIIStringEncoding error: NULL];
        if (portString.length) {
            _port = [portString integerValue];
            _completionBlock(self, nil); // nRepl was successfully started
        } else {
            _completionBlock(self, [NSError errorWithDomain: @"org.cocoanuts.s-explorer"
                                                       code: 404
                                                   userInfo: @{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"No nRepl port file found at '%@'", portFileURL]}]);
        }
        self.watcher = nil;

    }];

    
    [_task launch];
 }


/**
 * Configures the task according to the dictionary supplied. 
 * Changes usualy only take effect after the REPL task has been relaunched.
 **/
- (void) setSettings:(NSDictionary*) settings {
    _settings = settings;
}

- (NSString*) debugDescription {
    return [NSString stringWithFormat: @"%@ %@, listening on port %ld", [super debugDescription], self.task, self.port];
}

@end
