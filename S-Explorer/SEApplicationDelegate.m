//
//  SEApplicationDelegate.m
//  S-Explorer
//
//  Created by Dirk Theisen on 22.08.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import "SEApplicationDelegate.h"

@implementation SEApplicationDelegate

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (IBAction) openSchemeTutorial: (id) sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.scheme.com/tspl3/"]];
}

- (IBAction) openSchemeOverview: (id) sender {
    [[NSWorkspace sharedWorkspace] openURL: [[NSBundle mainBundle] URLForResource: @"r7rs-overview" withExtension:@"pdf"]];
}

- (IBAction) openSchemeStandard: (id) sender {
    [[NSWorkspace sharedWorkspace] openURL: [[NSBundle mainBundle] URLForResource: @"r7rs-standard" withExtension:@"pdf"]];
}

@end
