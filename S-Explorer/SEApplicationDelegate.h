//
//  SEApplicationDelegate.h
//  S-Explorer
//
//  Created by Dirk Theisen on 22.08.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SEAppDelegate ((SEApplicationDelegate*)[NSApp delegate])

@interface SEApplicationDelegate : NSObject

- (IBAction) openSchemeTutorial: (id) sender;

@end
