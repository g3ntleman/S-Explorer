//
//  SEDocumentController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 02.09.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEDocumentController.h"
#import "SEProject.h"

@interface NSSavePanel (SEDocumentController)

@property (nonatomic, strong) IBOutlet NSView* accessoryView;

@end

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
    
    // Set the default name for the file and show the panel.
    NSSavePanel*    panel = [NSSavePanel savePanel];
    
    panel.canCreateDirectories = YES;
    panel.accessoryView = nil; // todo
    panel.prompt = @"Create New Project";
    panel.title = @"New Project";
    panel.message = @"Please name a folder where your project will be created in.\nA project file with the same name (and 'sproj' extension) will be ceated in there.";
    panel.nameFieldLabel = @"Name:";
    
    // Extend save panel with template type:
    NSArray* objects;
    [[NSBundle mainBundle] loadNibNamed: @"SESavePanel" owner: panel topLevelObjects:&objects];
    NSView* accessory = panel.accessoryView;
    NSPopUpButton* button = [accessory viewWithTag: 13];
    
    NSArray* templatePaths = [[NSBundle mainBundle] pathsForResourcesOfType: @".setemplate" inDirectory:@"Templates"];
    
    [button removeAllItems];
    for (NSString* path in templatePaths) {
        NSString* templateTitle = [path.lastPathComponent stringByDeletingPathExtension];
        [button addItemWithTitle:templateTitle];
        [button.itemArray.lastObject setRepresentedObject:path];
    }

//    NSArray* templateNames = [templateNames map]
    
    //[panel setNameFieldStringValue:newName];
    [panel beginSheetModalForWindow: nil completionHandler: ^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL*  theFolder = [panel URL];
            NSError* error = nil;
            
            NSLog(@"User choose folder %@", theFolder);
            NSLog(@"User choose template %@", [button selectedItem]);
            
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
