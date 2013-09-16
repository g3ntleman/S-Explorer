//
//  SEDocumentController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 02.09.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEDocumentController.h"
#import "SEProject.h"

@implementation SEDocumentController

- (NSString*) defaultType {
    return SEProjectDocumentType;
}

- (id)makeUntitledDocumentOfType:(NSString *)typeName error:(NSError **)outError {
    return nil;
}

- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
    return nil;
}


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
    NSLog(@"Should show the assistant here.");
    
    
    // Set the default name for the file and show the panel.
    NSSavePanel*    panel = [NSSavePanel savePanel];
    
    panel.accessoryView = nil; // todo
    
    //[panel setNameFieldStringValue:newName];
    [panel beginSheetModalForWindow: nil completionHandler: ^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL*  theFolder = [panel URL];
            NSError* error = nil;
            
            NSLog(@"User choose %@", theFolder);
            
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm createDirectoryAtURL: theFolder withIntermediateDirectories: YES attributes: nil error: &error];
            [self openDocumentWithContentsOfURL: theFolder display: YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                NSLog(@"New Document opened.");
            }];
            
            // Write the contents in the new format.
        }
    }];
}


@end
