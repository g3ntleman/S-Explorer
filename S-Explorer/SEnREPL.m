//
//  SEREPL.m
//  S-Explorer
//
//  Created by Dirk Theisen on 10.11.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEnREPL.h"
#import "PseudoTTY.h"
#import "LVPathWatcher.h"

@interface SEnREPL ()

@property (strong, nonatomic) SEnREPLCompletionBlock completionBlock;
@property (strong, nonatomic) LVPathWatcher* watcher;
@property (strong, nonatomic) PseudoTTY* tty;


@end

#import <sys/socket.h>
#import <netinet/in.h>
#import <net/if.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <sys/ioctl.h>

#define SOCKET_NULL -1

/**
 * Returns an unused socket port or -1 on failure.
 */
//int OPGetUnusedSocketPort() {
//    
//    int socketFD = socket(AF_INET, SOCK_STREAM, 0);
//    
//    if (socketFD == SOCKET_NULL) {
//        NSString *reason = @"Error in socket() function";
//        NSLog(@"Finding free port: %@", reason);
//        return SOCKET_NULL;
//    }
//    
//    int status;
//    
//    // Set socket options
//    
//    status = fcntl(socketFD, F_SETFL, O_NONBLOCK);
//    if (status == -1) {
//        NSString *reason = @"Error enabling non-blocking IO on socket (fcntl)";
//        NSLog(@"Finding free port: %@", reason);
//        close(socketFD);
//        return SOCKET_NULL;
//    }
//    
//    int reuseOn = 1;
//    status = setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &reuseOn, sizeof(reuseOn));
//    if (status == -1) {
//        NSString *reason = @"Error enabling address reuse (setsockopt)";
//        NSLog(@"Finding free port: %@", reason);
//        close(socketFD);
//        return SOCKET_NULL;
//    }
//    
//    struct sockaddr_in sockaddr4;
//    memset(&sockaddr4, 0, sizeof(sockaddr4));
//    sockaddr4.sin_len         = sizeof(sockaddr4);
//    sockaddr4.sin_family      = AF_INET;
//    sockaddr4.sin_port        = htons(0);
//    sockaddr4.sin_addr.s_addr = htonl(INADDR_ANY);
//    
//    // Bind socket:
//    status = bind(socketFD, (const struct sockaddr *)&sockaddr4, sizeof(sockaddr4));
//    if (status == -1) {
//        NSString *reason = @"Error in bind() function";
//        NSLog(@"Finding free port: %@", reason);
//        close(socketFD);
//        return SOCKET_NULL;
//    }
//    
//    // bind() has assigned a free random socket port in sockaddr4. request it:
//    memset(&sockaddr4, 0, sizeof(sockaddr4));
//    socklen_t sockaddr4Len = sizeof(sockaddr4);
//    in_port_t result = SOCKET_NULL;
//    status = getsockname(socketFD, (struct sockaddr *)&sockaddr4, &sockaddr4Len);
//    if (status == 0) {
//        result = ntohs(sockaddr4.sin_port);
//    }
//    close(socketFD);
//    
//    return result;
//}




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
        
        if (_completionBlock && [string hasPrefix: @"nREPL"]) {
            NSRange portPrefixRange = [string rangeOfString: @"port "];
            NSScanner* scanner = [[NSScanner alloc] initWithString: string];
            [scanner setScanLocation: NSMaxRange(portPrefixRange)];
            [scanner scanInteger: &_port];
            _completionBlock(self, nil); // nRepl was successfully started
            _completionBlock = NULL;
        }
        
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
    
//    int port = OPGetUnusedSocketPort();
//    port = OPGetUnusedSocketPort();
    //    [commandArguments addObject: [NSString stringWithFormat: @":port %d", port]];
    [commandArguments addObject: @":headless"];

    
    
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
