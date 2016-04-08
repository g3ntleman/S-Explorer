//
//  SEDocumentController.m
//  S-Explorer
//
//  Created by Dirk Theisen on 02.09.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import "SEDocumentController.h"
#import "SEProjectDocument.h"

@interface NSSavePanel (SEDocumentController)

@property (nonatomic, strong) IBOutlet NSView* accessoryView;

@end

@implementation SEDocumentController

- (NSString*) defaultType {
    return SEProjectDocumentType;
}

//- (id) makeUntitledDocumentOfType:(NSString*) typeName error: (NSError**) outError {
//    return nil;
//}
//
//- (id) openUntitledDocumentAndDisplay: (BOOL) displayDocument error: (NSError**) outError {
//    return nil;
//}

- (void) openDocument: (id) sender {
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[SEProjectDocumentType];
    
    [self beginOpenPanel: panel forTypes: @[SEProjectDocumentType, @"public.folder"] completionHandler: ^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL* selectedURL = [[panel URLs] objectAtIndex:0];
            NSLog(@"selected URL: %@", selectedURL);
            [self openDocumentWithContentsOfURL: selectedURL
                                        display: YES
                              completionHandler: ^(NSDocument * _Nullable project, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
                                  NSLog(@"Opened URL %@ (Error %@)", selectedURL, error);
                                  NSLog(@"Got %@", project);
                              }];
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

- (void) openDocumentWithContentsOfURL: (NSURL*) url display: (BOOL) displayDocument completionHandler: (void (^)(NSDocument* document, BOOL documentWasAlreadyOpen, NSError* error)) completionHandler {
    
    // Find the project for the url given:
    // Check, if we are trying to open a file in a project that is already open:
    NSString* urlPath = url.path;
    for (SEProjectDocument* project in self.documents) {
        if (! [project isKindOfClass: [SEProjectDocument class]]) {
            continue;
        }
        NSString* projectPath = project.projectFolderItem.fileURL.path;
        if ([urlPath hasPrefix: projectPath]) {
            // Do not open any document, just show an existing one:
            NSString* filePath = [urlPath substringFromIndex: projectPath.length];
            SESourceItem* sourceItem = [[project projectFolderItem] childWithPath: filePath];
            if (displayDocument) {
                [project showWindows];
            }
            [project openSourceItem: sourceItem];
            completionHandler(project, YES, nil);
            return;
        }
    }
    // The source file specified in url is not already part of an open project document.
    
    if ([urlPath.lastPathComponent isEqualToString: @"project.clj"]) {
        NSURL* projectURL = [url URLByDeletingLastPathComponent];
        [self openDocumentWithContentsOfURL: projectURL display: displayDocument completionHandler: ^(NSDocument* _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
            [self openDocumentWithContentsOfURL: url display: displayDocument completionHandler: completionHandler];
        }];
        return;
    }
    
    
//    NSURL* projectFileURL = nil;
//    NSURL* projectFolderURL = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    

    
//    NSString* filename = nil;
    if ([fm fileExistsAtPath: [url path] isDirectory: &isDir]) {
        if (isDir) {
            url = [url URLByAppendingPathComponent: [[url lastPathComponent] stringByAppendingPathExtension: @"seproj"]];
            NSError* error = nil;

            
            NSDocument* document = [self openUntitledDocumentAndDisplay: displayDocument error: &error];
            document.fileURL = url;
            
//            if (displayDocument) {
//                [document makeWindowControllers];
//            }
        }
    }
    
    [super openDocumentWithContentsOfURL: url display: displayDocument completionHandler: completionHandler];

    
//            projectFolderURL = url;
//        } else {
//            if ([[url pathExtension] isEqualToString: @"seproj"]) {
//                projectFileURL = url;
//                projectFolderURL = [projectFileURL URLByDeletingLastPathComponent];
//            } else {
//                // We are trying to open a source file (not a project file or directory):
//                filename = [url lastPathComponent];
//                projectFolderURL = [url URLByDeletingLastPathComponent];
//                isDir = YES;
//            }
//        }
//    }
//    NSLog(@"Opening project at folder %@", url);
//    NSAssert(projectFolderURL, @"projectFolderURL not determined.");
//    
//    if (! projectFileURL) {
//        projectFileURL = [projectFolderURL URLByAppendingPathComponent: [projectFolderURL.lastPathComponent stringByAppendingPathExtension: @"seproj"]];
//    }
//    
//    NSAssert(projectFileURL, @"projectFileURL not determined.");
//
//    // Project found. projectFileURL now points to a project file.
//
//    // Check, if file exists at URL:
//    if ([fm fileExistsAtPath: [projectFileURL path]]) {
//        // Project file exists:
//        [super openDocumentWithContentsOfURL:url display:displayDocument completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
//            completionHandler(document, documentWasAlreadyOpen, error); // "super" call
//            // Now that the project is open, show the SESourceItem for filename (if any):
//            SEProjectDocument* project = (SEProjectDocument*)document;
//            if (filename.length) {
//                SESourceItem* sourceItem = [[project projectFolderItem] childWithPath: filename];
//                [project openSourceItem: sourceItem];
//            }
//        }];
//    } else {
//        // No project file exists. Create new document and set fileURL, return it:
//        NSError* error = nil;
//        SESourceItem* sourceDocument = [[SESourceItem alloc] initWithContentsOfURL: url ofType: nil error: nil];
//        
//        completionHandler(sourceDocument, NO, error);
//    }
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
    [panel beginSheetModalForWindow: self.currentDocument.windowForSheet completionHandler: ^(NSInteger result){
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
                SEProjectDocument* project = (SEProjectDocument*)document;
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
