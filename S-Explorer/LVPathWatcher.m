//
//  LVPathWatcher.m
//  Leviathan
//
//  Created by Steven Degutis on 11/6/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//
// Released under MIT license.
// Copyright (c) 2013 Steven Degutis

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LVPathWatcher.h"

@interface LVPathWatcher ()

@property FSEventStreamRef stream;
@property (copy) void(^handler)();

@end

@implementation LVPathWatcher

void fsEventsCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[])
{
    if (eventFlags[0] & kFSEventStreamEventFlagItemModified) {
        LVPathWatcher* watcher = (__bridge LVPathWatcher*)clientCallBackInfo;
        [watcher fileChanged];
    }
}

- (void) dealloc {
    if (self.stream) {
        FSEventStreamStop(self.stream);
        FSEventStreamInvalidate(self.stream);
        FSEventStreamRelease(self.stream);
    }
}

+ (LVPathWatcher*) watcherFor:(NSURL*)url handler:(void(^)())handler {
    LVPathWatcher* watcher = [[LVPathWatcher alloc] init];
    watcher.handler = handler;
    [watcher setup:url];
    return watcher;
}

- (void) setup:(NSURL*)url {
    FSEventStreamContext context;
    context.info = (__bridge void*)self;
    context.version = 0;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    self.stream = FSEventStreamCreate(NULL,
                                      fsEventsCallback,
                                      &context,
                                      (__bridge CFArrayRef)@[[[url path] stringByStandardizingPath]],
                                      kFSEventStreamEventIdSinceNow,
                                      0.4,
                                      kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagFileEvents);
    FSEventStreamScheduleWithRunLoop(self.stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self.stream);
}

- (void) fileChanged {
    self.handler();
}

@end
