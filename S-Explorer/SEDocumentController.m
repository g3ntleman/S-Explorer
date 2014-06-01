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

- (id) makeUntitledDocumentOfType:(NSString*) typeName error: (NSError**) outError {
    return nil;
}

- (id) openUntitledDocumentAndDisplay: (BOOL) displayDocument error: (NSError**) outError {
    return nil;
}

- (void) openDocument: (id) sender {
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[SEProjectDocumentType];
    
    [self beginOpenPanel: panel forTypes: @[SEProjectDocumentType, @"public.folder"] completionHandler:^(NSInteger result) {
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

//- (id) makeDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError **)outError {
//    return [super makeDocumentForURL: urlOrNil withContentsOfURL: contentsURL ofType:typeName error: outError];
//}

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    NSString* filename = nil;
    if ([fm fileExistsAtPath: [url path] isDirectory: &isDir]) {
        if (! isDir && ! [[url pathExtension] isEqualToString: @"seproj"]) {
        // We are trying to open a file (not a project file or directory):
            filename = [url lastPathComponent];
            url = [url URLByDeletingLastPathComponent];
            isDir = YES;
        }
    }
    NSLog(@"Opening project at folder %@", url);
    
    if (isDir) {
        url = [url URLByAppendingPathComponent: [url.lastPathComponent stringByAppendingPathExtension: @"seproj"]];
    }

    [super openDocumentWithContentsOfURL:url display:displayDocument completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
        completionHandler(document, documentWasAlreadyOpen, error); // "super" call
        // Now that the project is open, show the SESourceItem for filename:
        SEProject* project = (SEProject*)document;
        if (filename.length) {
            SESourceItem* sourceItem = [[project projectFolderItem] childItemWithName: filename];
            [project openSourceItem: sourceItem];
        }
    }];
}




- (IBAction) newDocument: (id) sender {
    
    // Set the default name for the file and show the panel.
    NSSavePanel*    panel = [NSSavePanel savePanel];
    
    panel.canCreateDirectories = YES;
    panel.accessoryView = nil; // todo
    panel.prompt = @"Create New Project";
    panel.title = @"New Project";
    panel.message = @"Please name a folder where your project will be created in.\nA project file with the same name (and 'seproj' extension) will be ceated in there.";
    panel.nameFieldLabel = @"Name:";
    
    // Extend save panel with template type:
    NSArray* objects;
    [[NSBundle mainBundle] loadNibNamed: @"SESavePanel" owner: panel topLevelObjects:&objects];
    NSView* accessory = panel.accessoryView;
    NSPopUpButton* templateButton = [accessory viewWithTag: 13];
    
    NSArray* templatePaths = [[NSBundle mainBundle] pathsForResourcesOfType: @".setemplate" inDirectory:@"Templates"];
    
    [templateButton removeAllItems];
    for (NSString* path in templatePaths) {
        NSString* templateTitle = [path.lastPathComponent stringByDeletingPathExtension];
        [templateButton addItemWithTitle: templateTitle];
        [templateButton.itemArray.lastObject setRepresentedObject: path];
    }

//    NSArray* templateNames = [templateNames map]
    
    //[panel setNameFieldStringValue:newName];
    [panel beginSheetModalForWindow: nil completionHandler: ^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL* projectURL = [panel URL];
            NSString* templateName = [[templateButton selectedItem] title];
            NSError* error = nil;
            
            NSLog(@"User choose folder %@", projectURL);
            NSLog(@"User choose template %@", templateName);
            
            NSFileManager *fm = [NSFileManager defaultManager];
            if (! [fm fileExistsAtPath: [projectURL path] isDirectory: NULL]) {
                [fm createDirectoryAtURL: projectURL withIntermediateDirectories: YES attributes: nil error: &error];
            }
            NSString* templatePath = [[templateButton selectedItem] representedObject];
            // Copy content of templatePath to projectFolder:
            for (NSString* sourceFile in [fm contentsOfDirectoryAtPath: templatePath error:&error]) {
                NSURL* sourceURL = [NSURL fileURLWithPathComponents:@[templatePath, sourceFile]];
                // Most files are just copied over:
                NSString* targetFile = sourceFile;
                // Any project file is changed to pathname
                if ([sourceFile.pathExtension isEqualToString: @"seproj"]) {
                    targetFile = [[projectURL lastPathComponent] stringByAppendingPathExtension:@"seproj"];
                }
                NSURL* targetURL = [projectURL URLByAppendingPathComponent: targetFile];
                
                [fm copyItemAtURL: sourceURL toURL: targetURL error: &error];
                if (error) {
                    NSLog(@"Error copying %@ to %@: %@", sourceFile, projectURL, error);
                }
            }
            // Open the new Project:
            [self openDocumentWithContentsOfURL: projectURL display: YES completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                NSLog(@"New Document opened: %@", document);
                SEProject* project = (SEProject*)document;
                if (error) {
                    [[NSAlert alertWithError:error] runModal];
                } else {
                    [project saveProjectSettings];
                }
            }];
        }
    }];
}


@end
