//
//  SEREPL.m
//  S-Explorer
//
//  Created by Dirk Theisen on 10.11.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import "SEREPLServer.h"
#import "PseudoTTY.h"
#include <arpa/inet.h>

@interface SEREPLServer ()

@property (strong, nonatomic) SEREPLServerCompletionBlock completionBlock;
@property (strong, nonatomic) PseudoTTY* tty;
@property (nonatomic) in_port_t port;
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



@implementation SEREPLServer

+ (in_port_t) availableTCPPort {
    
    int result = 0;
    struct sockaddr_in addr;
    socklen_t len = sizeof(addr);
    addr.sin_port = 0;
    inet_aton("0.0.0.0", &addr.sin_addr);
    
    int sock = socket(AF_INET, SOCK_STREAM, 0);

    if (sock < 0) {
        perror("socket()");
        return -1;
    }
    
    int iSetOption = 1;
    result = setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (char*)&iSetOption, sizeof(iSetOption));

    if (bind(sock, (struct sockaddr*) &addr, sizeof(addr))) {
        perror("bind()");
        return -1;
    }
    if (getsockname(sock, (struct sockaddr*) &addr, &len)) {
        perror("getsockname()");
        return -1;
    }
    
    in_port_t port = (addr.sin_port);
    
    result = close(sock);
    
    NSLog(@"Found free server port #%d", port);
    
    return port;
}

- (id) initWithSettings: (NSDictionary*) initialSettings {
    
    NSParameterAssert(initialSettings!=nil);
    if (self = [self init]) {
        
        NSLog(@"Starting REPL Server with settings %@.", initialSettings);
        
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
        
        
//        if (_completionBlock && [string hasPrefix: @"nREPL"]) {
//            NSRange portPrefixRange = [string rangeOfString: @"port "];
//            NSScanner* scanner = [[NSScanner alloc] initWithString: string];
//            [scanner setScanLocation: NSMaxRange(portPrefixRange)];
//            [scanner scanInteger: &_port];
//            _completionBlock(self, nil); // nRepl was successfully started
//            _completionBlock = NULL;
//        } else {
            NSLog(@"Read: '%@'", string);
//        }
        
        [filehandle readInBackgroundAndNotify];
    } else {
        if (! self.port) {
            NSLog(@"\n--> Process exited with exit code %d.\n", self.task.terminationStatus);
        }
        _completionBlock(self, [[NSError alloc] initWithDomain: @"NSTaskErrorDomain" code:self.task.terminationStatus userInfo: nil]); // nRepl was successfully started
    }
}

/**
 * Starts the REPL task. A previous task is terminated.
 **/
- (void) startWithCompletion: (SEREPLServerCompletionBlock) block {
    
    // Stop a running task if neccessary:
    [self stop];
    
    _completionBlock = block;
    _task = [[NSTask alloc] init];

    //NSError* error = nil;
    //NSMutableArray* commandArguments = [_settings[@"RuntimeArguments"] mutableCopy];
    NSString* runtimeSupportPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"Runtime-Support/Clojure"];
    self.port = [SEREPLServer availableTCPPort];
    
    //NSArray* commandArgumentTemplates = self.settings[@"RuntimeArguments"];
    
    //commandArgumentTemplates = @[@"-Dclojure.server.toolrepl={:port %PORT :accept replicant.util/data-repl}",
    //                             @"clojure.main"];
    
    NSMutableArray* commandArguments = [NSMutableArray array];
    
    NSString* expression = [NSString stringWithFormat: @"(do (load-file \"%@/replicant/util.clj\")(replicant.util/run-tool-repl %@))", runtimeSupportPath, @(self.port)];
    
    //[commandArguments addObject: @"/usr/local/bin/java"];
    [commandArguments addObject: @"clojure.main"];
    [commandArguments addObject: @"-e"];
    [commandArguments addObject: expression];
    
//    for (NSString* template in commandArgumentTemplates) {
//        NSString* argument = [template stringByReplacingOccurrencesOfString: @"%PORT" withString: [@(self.port) description]];
//        [commandArguments addObject: argument];
//    }
    
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
    
    NSString* toolPath = self.settings[@"RuntimeTool"];
    
    if (! [[NSFileManager defaultManager] isExecutableFileAtPath: toolPath]) {
        _completionBlock(self, [NSError errorWithDomain: @"org.cocoanuts.s-explorer"
                                                   code: 404
                                               userInfo: @{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"No Executable file at '%@'", toolPath]}]);
        return;
    }
    
    _task.launchPath = toolPath;
    _task.currentDirectoryPath = workingDirectory;
    
    NSDictionary* defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary* environment = [[NSMutableDictionary alloc] initWithDictionary: defaultEnvironment];
    [environment setObject: @"YES" forKey: @"NSUnbufferedIO"];
    [environment setObject: @"en_US-iso8859-1" forKey: @"LANG"];
    //NSString* jvmOpts = [NSString stringWithFormat: @"-Dclojure.server.datarepl={:port %lu :accept 'replicant.util/data-repl} ", (unsigned long)5555];
    //jvmOpts = [jvmOpts stringByAppendingFormat: @"-Djava.library.path=%@", runtimeSupportPath];
    
    //environment[@"JVM_OPTS"] = jvmOpts;
    [environment setObject: self.settings[@"JavaClassPath"] forKey: @"CLASSPATH"];
 ; //environment[@"CLASSPATH"];
    //environment[@"LEIN_JVM_OPTS"] = [NSString stringWithFormat: @"-cp %@", runtimeSupportPath];
    //[classPath ? classPath : @"" stringByAppendingString: [NSString stringWithFormat: @";%@", runtimeSupportPath]];
    
    [_task setEnvironment: environment];
    [_task setArguments: commandArguments];
    
    const SEREPLServerCompletionBlock cblock = _completionBlock;
    
    _task.terminationHandler =  ^void (NSTask* task) {
        NSLog(@"REPL Task %@ Terminated with return code %d", task, task.terminationStatus);
        if (cblock) {
            if (task.terminationStatus != 0) {
                NSError* error = [NSError errorWithDomain: @"NSTask" code: task.terminationStatus
                                                 userInfo: @{@"reason": @(task.terminationReason)}];
                cblock(nil, error);
            }
            _task = nil; // break retain cycle
            _completionBlock = NULL;
        }
    };
    
    NSLog(@"Launching %@: %@ %@\nEnvironment:\n%@", _task, _task.launchPath, [_task.arguments componentsJoinedByString: @" "], environment);
    
    
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_completionBlock) {
            _completionBlock(self, nil); // REPL Server was successfully started
        }
    });
    
 }


/**
 * Configures the task according to the dictionary supplied. 
 * Changes usualy only take effect after the REPL task has been relaunched.
 **/
- (void) setSettings:(NSDictionary*) settings {
    _settings = settings;
}

- (NSString*) debugDescription {
    return [NSString stringWithFormat: @"%@ %@, listening on port %hu", [super debugDescription], self.task, self.port];
}

@end
