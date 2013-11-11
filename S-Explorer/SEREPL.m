//
//  SEREPL.m
//  S-Explorer
//
//  Created by Dirk Theisen on 10.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEREPL.h"

@implementation SEREPL

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
        if (_port) {
            _port += 1; // use different port each time?
        }
    }
}

/**
 * Starts the REPL task. A previous task is terminated.
 **/
- (void) start {
    // Stop a running task as neccessary:
    [self stop];
    
    _task = [[NSTask alloc] init];

    if (! _port) {
        _port = 50555;
    }
    
    
    //NSError* error = nil;
    NSArray* commandArguments = _settings[@"RuntimeArguments"];
    NSMutableArray* launchArguments = [[NSMutableArray alloc] init];
    
    NSString* workingDirectory = _settings[@"WorkingDirectory"];
    
    NSString* sourceFile = _settings[@"StartupSource"];
    if (sourceFile.length) {
        [launchArguments addObject: [NSString stringWithFormat: @"-l%@", sourceFile]];
    }
    
    NSString* expression = _settings[@"StartupExpression"];
    if (expression.length) {
        [launchArguments addObject: [NSString stringWithFormat: @"-e%@", expression]];
    }
    
    NSString* tool = _settings[@"RuntimeTool"];

    
    if (commandArguments.count + launchArguments.count) {
        _task.arguments = commandArguments;
            if (! _task.arguments) {
                _task.arguments = @[];
            }
            _task.arguments = [_task.arguments arrayByAddingObjectsFromArray: launchArguments];
    }
    
    _task.launchPath = tool;
    _task.currentDirectoryPath = workingDirectory;
    
    NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    //[environment setObject: @"YES" forKey: @"NSUnbufferedIO"];
    //[environment setObject: @"en_US-iso8859-1" forKey: @"LANG"];
    
    [_task setEnvironment: environment];
    
    
//    _task.terminationHandler =  ^void (NSTask* task) {
//        [theReplView setEditable: NO];
//    };
    
    NSLog(@"Launching '%@' with %@", _task.launchPath, _task.arguments);
    
    [_task launch];
 }


/**
 * Configures the task according to the dictionary supplied. 
 * Changes usualy only take effect after the REPL task has been relaunched.
 **/
- (void) setSettings:(NSDictionary*) settings {
    _settings = settings;
}

@end
