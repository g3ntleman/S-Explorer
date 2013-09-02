//
//  BRProject
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "SEProject.h"
#import "NSAlert+OPBlocks.h"
#import "SESourceItem.h"
#import "NSDictionary+OPImmutablility.h"
#import "NoodleLineNumberView.h"
#import "OPUtilityFunctions.h"


@implementation SEProject {
    NSMutableDictionary* uiSettings;
}

@synthesize tabbedSourceItems;
@synthesize sourceTab;
@synthesize sourceList;
@synthesize projectSettings;
@synthesize currentLanguage;
@synthesize projectFolderItem;

- (id) init {
    
    self.currentLanguage = @"Chibi-Scheme";
    
    NSURL* sourceURL = [[NSBundle mainBundle] URLForResource: @"S-Explorer-support" withExtension: @"scm"];
    
    return [self initWithContentsOfURL: sourceURL ofType:@"scm" error: NULL];
    
}

- (id) initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    
    if (self = [super init]) {
        
        self.tabbedSourceItems = @{};
        BOOL isDir = NO;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: url.path isDirectory: &isDir];
        if (isDir) {
            self = [self initWithContentsOfURL: [url URLByAppendingPathComponent: [url.lastPathComponent stringByAppendingPathExtension: @"sproj"]] ofType: @"org.cocoanuts.s-explorer-project" error: outError];
        } else {
            NSLog(@"Opening type %@", typeName);
            
            projectFolderItem = [[SESourceItem alloc] initWithFileURL: [url URLByDeletingLastPathComponent]];
            
            if ([typeName isEqualToString: @"org.cocoanuts.s-explorer-project"]) {
            } else {
                SESourceItem* singleSourceItem = [projectFolderItem childWithName: [url lastPathComponent]];
                
                [self setSourceItem: singleSourceItem forIndex: 0];
            }
        }
        return self;
    }
    
    return nil;
}

/**
 * index should be 0..3 while item may be nil to indicate a removal.
 */
- (void) setSourceItem: (SESourceItem*) item forIndex: (NSUInteger) index {
    
    NSParameterAssert(index<4);
    NSNumber* indexNumber = @(index);
    if (item) {
        NSParameterAssert([item isKindOfClass: [SESourceItem class]]);

        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryBySettingObject: item forKey: indexNumber];
    } else {
        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryByRemovingObjectForKey: indexNumber];
    }
    
    [sourceTab setEnabled: item!=nil forSegment: index];
    [sourceTab setLabel: item.relativePath forSegment: index];
    
    if (index == sourceTab.selectedSegment) {
        NSUInteger row = [sourceList rowForItem: item];
        [sourceList selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
                byExtendingSelection: NO];
    }
    
}

//- (BOOL) validateMenuItem:(NSMenuItem *)menuItem {
//    return YES;
//}

- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>) anItem {

//    if (anItem == sourceTab) {
//        
//        [sourceTab setEnabled: tabbedSourceItems[@0] != nil forSegment: 0];
//        [sourceTab setEnabled: tabbedSourceItems[@1] != nil forSegment: 1];
//        [sourceTab setEnabled: tabbedSourceItems[@2] != nil forSegment: 2];
//        [sourceTab setEnabled: tabbedSourceItems[@3] != nil forSegment: 3];
//    }
    return YES;
}

- (NSString *)windowNibName {
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"SEProject";
}

- (SESourceItem*) currentSourceItem {
    SESourceItem* sourceItem = self.tabbedSourceItems[@(sourceTab.selectedSegment)];
    return sourceItem;
}

- (void) setCurrentSourceItem: (SESourceItem*) sourceItem {
    
    [self setSourceItem: sourceItem forIndex: sourceTab.selectedSegment];
    
    NSTextStorage* textStorage = self.editorController.textEditorView.textStorage;
    NSString* fileContent = sourceItem.content;
    if (! fileContent)
        fileContent = @"";
    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont fontWithName: @"Menlo-Bold" size: 13.0], NSFontAttributeName, nil, nil];
    NSAttributedString* attributedContent = [[NSAttributedString alloc] initWithString: fileContent attributes: attributes];
    textStorage.attributedString = attributedContent;
    
    // Colorize scheme files:
    if ([sourceItem.relativePath.pathExtension isEqualToString: @"scm"]) {
        [self.editorController.textEditorView colorize: self];
    }
}

- (void) selectSourceTabWithIndex: (NSUInteger) tabIndex {
    SESourceItem* sourceItem = self.tabbedSourceItems[@(tabIndex)];
    [self setCurrentSourceItem: sourceItem];
}

- (NSMutableDictionary*) projectSettings {
    
    if (! projectSettings) {
        NSString* projectFolderPath = self.projectFolderItem.absolutePath;
        NSString* projectFilePath = [projectFolderPath stringByAppendingPathComponent: [self.projectFolderItem.relativePath stringByAppendingPathExtension:@"sproj"]];
        NSError* error = nil;
        NSData* projectData = [NSData dataWithContentsOfFile: projectFilePath];
        if (projectData) {
            projectSettings = [NSPropertyListSerialization propertyListWithData: projectData options: NSPropertyListMutableContainers format: NULL error: &error];
        } else {
            projectSettings = [[NSMutableDictionary alloc] init];
        }
    }
    return projectSettings;
}

- (NSString*) uiSettingsPath {
    NSString* uiFolderPath = self.projectFolderItem.absolutePath;
    NSString* uiFilePath = [uiFolderPath stringByAppendingPathComponent: @".UISettings.plist"];
    return uiFilePath;
}

- (NSMutableDictionary*) uiSettings {
    
    if (! uiSettings) {
        NSError* error = nil;
        NSData* uiData = [NSData dataWithContentsOfFile: [self uiSettingsPath]];
        if (uiData) {
            uiSettings = [NSPropertyListSerialization propertyListWithData: uiData
                                                                   options: NSPropertyListMutableContainers
                                                                    format: NULL
                                                                     error: &error];
        }
        if (error) {
            NSLog(@"Error reading '%@': %@", [self uiSettingsPath], error);
        }
        
        if (! uiSettings) {
            uiSettings = [[NSMutableDictionary alloc] init];
        }
        if (! uiSettings[@"expandedFolders"]) {
            uiSettings[@"expandedFolders"] = [[NSMutableDictionary alloc] init];
        }
    }
    return uiSettings;
}

- (void) uiSettingsNeedSave {
    // TODO: save later (on idle?)
    BOOL done = [self.uiSettings writeToFile: [self uiSettingsPath] atomically: YES];
    if (! done) {
        NSLog(@"Warning: Unable to write uiSettings to '%@'.", [self uiSettingsPath]);
    }
}


- (void) awakeFromNib {
}



- (IBAction) sourceTableAction: (id) sender {
    NSLog(@"sourceTableAction.");
    SESourceItem* selectedSourceItem = [self.sourceList itemAtRow: self.sourceList.selectedRow];
    
    if (selectedSourceItem.isTextItem) {
        [self setCurrentSourceItem: selectedSourceItem];
    }
}

- (IBAction) selectSourceTab: (id) sender {
    
    NSLog(@"selected tab #%lu", sourceTab.selectedSegment);
    SESourceItem* sourceItem = self.tabbedSourceItems[@(sourceTab.selectedSegment)];
    
    [self setCurrentSourceItem: sourceItem];
}

- (IBAction) saveCurrentSourceItem: (id) sender {
    
    SESourceItem* currentSource = self.currentSourceItem;
    
    if (currentSource.contentHasChanged) {
        NSError* error = nil;
        [currentSource saveContentWithError: &error];
        if (error) {
            NSBeep();
            NSLog(@"Error saving %@: %@", currentSource, error);
        }
    }
}

- (IBAction) revertCurrentSourceItemToSaved: (id) sender {
    
    SESourceItem* currentSource = self.currentSourceItem;
    if (currentSource.contentHasChanged) {
        [currentSource revertContent];
        [self setCurrentSourceItem: currentSource];
    }
}

- (void) checkLibraryAlias {
    
    NSString* libraryFolder = self.languageDictionary[@"libraryFolder"];
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath: libraryFolder isDirectory: &isDir] && isDir) {
        
    }
}


- (NSString*) currentLanguage {
    return currentLanguage; //@"Chibi-Scheme";
}

- (void) setCurrentLanguage:(NSString *)language {
    currentLanguage = language;
    NSDictionary* langDict = self.languageDictionary;
    NSAssert(langDict, @"No language definition for %@ in info.plist.", language);
    
    [self checkLibraryAlias];
}

- (NSDictionary*) languageDictionary {
    NSDictionary* languageDictionaries = [[NSBundle mainBundle] infoDictionary][@"LanguageSupport"];
    return languageDictionaries[self.currentLanguage];
}

- (IBAction) runProject: (id) sender {
    [self.replController run: sender];
}

- (void) windowControllerDidLoadNib: (NSWindowController*) aController {
    
    [super windowControllerDidLoadNib: aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    
    // Check, wether the user wants to create a project (from a folder):
    
    
    
    
    [self.sourceList setDraggingSourceOperationMask: NSDragOperationLink forLocal: NO];

    
    NSError* error = nil;
    [self.replController setCommand: @"/usr/local/bin/chibi-scheme"
                      withArguments: @[]
                   workingDirectory: self.projectFolderItem.absolutePath
                           greeting: self.languageDictionary[@"WelcomeMessage"]
                              error: &error];
    
    [self.replController run: self];
    
    if (error) {
        [[NSAlert alertWithError: error] runWithCompletion:^(NSInteger buttonIndex) {
            [self performSelector: @selector(close) withObject: nil afterDelay: 0.1];
        }];
    }
    
//    vm = [[CSVM alloc] init];
    
//    NSString*sage"//    [vm locationOfProcedureNamed: @"map"];
//    self.replController.virtualMachine = vm;

    [self setSourceItem: tabbedSourceItems[@(sourceTab.selectedSegment)] forIndex: sourceTab.selectedSegment];
    [self selectSourceTabWithIndex: 0];
    
    for (NSString* path in self.uiSettings[@"expandedFolders"]) {
        SESourceItem* item = [self.projectFolderItem childWithPath: path];
        [self.sourceList expandItem: item];
    }
    
}

+ (BOOL) autosavesInPlace {
    return NO; // Turn on later!
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}

- (SESourceItem*) projectFolderItem {
    if (! projectFolderItem) {
        projectFolderItem = [[SESourceItem alloc] initWithFileURL: [self fileURL]];
    }
    return projectFolderItem;
}

@end

@implementation SEProject (SourceOutlineViewDataSource)
// Data Source methods

- (NSInteger) outlineView:(NSOutlineView*) outlineView numberOfChildrenOfItem: (id) item {
    if (item == nil) {
        item = self.projectFolderItem;
    }
    NSInteger noc = [[item children] count];
    return noc;
}


- (BOOL) outlineView: (NSOutlineView*) outlineView isItemExpandable: (id) item {
    if (item == nil) {
        item = self.projectFolderItem;
    }
    return  [item children] != nil;
}


- (id) outlineView: (NSOutlineView*) outlineView child:(NSInteger)index ofItem:(id)item {
    
    if (item == nil) {
        item = self.projectFolderItem;
    }
        
    return [item children][index];
}


- (id) outlineView: (NSOutlineView*) outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    
    //NSLog(@"Finding objectValue for %@", item);
    if (item == nil) {
        item = self.projectFolderItem;
    }
    
    return [item relativePath];
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    SESourceItem* sourceItem = item;
    NSString* path = sourceItem.longRelativePath;
    self.uiSettings[@"expandedFolders"][path] = @YES;
    [self uiSettingsNeedSave];
    return YES;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    SESourceItem* sourceItem = item;
    NSString* path = sourceItem.longRelativePath;
    [self.uiSettings[@"expandedFolders"] removeObjectForKey: path];
    [self uiSettingsNeedSave];
    return YES;
}

- (IBAction) revealInFinder: (id) sender {
    SESourceItem* selectedItem  = [sourceList itemAtRow: sourceList.selectedRowIndexes.firstIndex];
    NSString* selectedItemPath = selectedItem.absolutePath;
    [[NSWorkspace sharedWorkspace] selectFile: selectedItemPath inFileViewerRootedAtPath: nil];
}



- (BOOL) outlineView: (NSOutlineView*) outlineView writeItems: (NSArray*) items toPasteboard:(NSPasteboard *)pboard {
    // Set the pasteboard for File promises only
    [pboard declareTypes: @[NSURLPboardType] owner:self];
    
    // The pasteboard must know the type of files being promised:
    
    NSMutableSet* urlStrings = [NSMutableSet set];
    for (SESourceItem* item in items) {
        NSString* urlString = [[NSURL fileURLWithPath: item.absolutePath] absoluteString];
        if (urlString.length) {
            [urlStrings addObject: urlString];
        }
    }
    
    if (urlStrings.count) {
        // Give the pasteboard the file extensions:
        [pboard setPropertyList: urlStrings.allObjects forType: NSURLPboardType];
    }
    return YES;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    // Return one of the following:
    // NSDragOperation{Copy, Link, Generic, Private, Move,
    //                 Delete, Every, None}
    if (isLocal) {
        //return what you want to happen if it's coming from your app;
    }
    //return what you want to happen if it isn't;
    return NSDragOperationLink;
}


/* In 10.7 multiple drag images are supported by using this delegate method. */
- (id <NSPasteboardWriting>)outlineView: (NSOutlineView*) outlineView pasteboardWriterForItem: (id) item {
    return (SESourceItem*)item;
}

- (NSView*) outlineView: (NSOutlineView*) outlineView viewForTableColumn: (NSTableColumn*) tableColumn item:(id) item {
    
    NSTableCellView *result = [outlineView makeViewWithIdentifier: [tableColumn identifier] owner: self];

    result.textField.stringValue = [item relativePath];
    result.imageView.image = [[NSWorkspace sharedWorkspace] iconForFileType: [item relativePath].pathExtension];
    
    return result;
}

- (IBAction) evaluateSelection: (id) sender {
    
    NSRange evalRange = self.editorController.textEditorView.selectedRange;
    if (! evalRange.length) {
        evalRange = [self.editorController topLevelExpressionContainingLocation: evalRange.location];
        if (! evalRange.length) {
            NSBeep();
            return;
        }
    }
    
    NSString* evalString = [self.editorController.textEditorView.string substringWithRange:evalRange];
    SEREPLController* replController = self.replController;
    NSLog(@"Evaluating selection: '%@'", evalString);
    [replController evaluateString: evalString];
}

//- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//    if ([item isKindOfClass:[ATDesktopFolderEntity class]]) {
//        // Everything is setup in bindings
//        return [outlineView makeViewWithIdentifier:@"GroupCell" owner:self];
//    } else {
//        NSView *result = [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
//        if ([result isKindOfClass:[ATTableCellView class]]) {
//            ATTableCellView *cellView = (ATTableCellView *)result;
//            // setup the color; we can't do this in bindings
//            cellView.colorView.drawBorder = YES;
//            cellView.colorView.backgroundColor = [item fillColor];
//        }
//        // Use a shared date formatter on the DateCell for better performance. Otherwise, it is encoded in every NSTextField
//        if ([[tableColumn identifier] isEqualToString:@"DateCell"]) {
//            [(id)result setFormatter:_sharedDateFormatter];
//        }
//        return result;
//    }
//    return nil;
//}



//- (NSArray*) outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL*)dropDestination forDraggedRowsWithIndexes:(NSIndexSet*)indexSet
//{
//    // return of the array of file names
//    NSMutableArray *draggedFilenames = [NSMutableArray array];
//    
//    // iterate the selected files
//    NSArray * selectedObjects = [yourNSArrayController selectedObjects];
//    
//    for (NSManagedObject *o in selectedObjects)
//    {
//        [draggedFilenames addObject:[o valueForKey:@"filename"]];
//        
//        // the file's pretty filename (i.e. filename.txt)
//        NSString *filename = [o valueForKey:@"filename"];
//        
//        // the file's most recent version's unique id
//        NSString *fullPathToOriginal = [NSString stringWithFormat:@"%@/%@", @"path to the original file", filename];
//        NSString *destPath = [[dropDestination path] stringByAppendingPathComponent:filename];
//        
//        // if a file with the same name exists on the destination, append " - Copy" to the filename
//        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:destPath];
//        
//        if (fileExists)
//        {
//            filename = [NSString stringWithFormat:@"%@ - Copy.%@", [[filename lastPathComponent] stringByDeletingPathExtension],[filename pathExtension]];
//        }
//        
//        // now perform the actual copy using the method of your choosing
//    }
//    
//    return draggedFilenames;
//}


- (BOOL) writeToURL: (NSURL*) absoluteURL ofType: (NSString*) typeName error: (NSError**) outError {
    NSLog(@"Should writeToURL %@ (%@)", absoluteURL, typeName);
    return YES;
}

- (IBAction) newDocumentFromTemplate: (id) sender {
    
}



@end
