//
//  SEDocumentController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 02.09.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEDocumentController.h"

@implementation SEDocumentController


- (void) openDocument: (id) sender {
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[@"org.cocoanuts.s-explorer-project"];
    
    [self beginOpenPanel: panel forTypes: @[@"org.cocoanuts.s-explorer-project", @"public.folder"] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL* selectedURL = [[panel URLs] objectAtIndex:0];
            NSLog(@"selected URL: %@", selectedURL);
            NSError* error = nil;
            id project = [self openDocumentWithContentsOfURL: selectedURL display: YES error: &error];
            NSLog(@"Opened URL %@ (Error %@)", selectedURL, error);
            NSLog(@"Got %@", project);
        }
    }];
    
//    [panel beginSheetModalForWindow:nil
//                  completionHandler:^(NSInteger result) {
//                      if (result == NSFileHandlingPanelOKButton) {
//                          NSURL* selectedURL = [[panel URLs] objectAtIndex:0];
//                          NSLog(@"selected URL: %@", selectedURL);
//                          NSError* error = nil;
//                          [self openDocumentWithContentsOfURL: selectedURL display: YES error: &error];
//                          NSLog(@"Opened URL %@ (Error %@)", selectedURL, error);
//                      }
//                  }];
}

- (IBAction) newDocument: (id) sender {
    // Extend open panel with template type:
}


@end
