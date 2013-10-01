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
#import "OPTabView.h"

NSString* SEProjectDocumentType = @"org.cocoanuts.s-explorer.project";

@interface SEProject ()
@property (readonly) NSString* uiSettingsPath;
@end

@implementation SEProject {
    NSMutableDictionary* uiSettings;
}

@synthesize tabbedSourceItems;
@synthesize allREPLControllers;
@synthesize sourceTabView;
@synthesize sourceList;
@synthesize projectSettings;
@synthesize currentLanguage;
@synthesize projectFolderItem;


- (id) init {
    return nil;
}

- (id) initForURL: (NSURL*) absoluteDocumentURL withContentsOfURL: (NSURL*) absoluteDocumentContentsURL ofType: (NSString*) typeName error: (NSError**) outError {
    return [self initWithContentsOfURL: absoluteDocumentURL ofType: typeName error: outError];
}

    
- (id) initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {

    if (self = [super init]) {
        tabbedSourceItems = @{};
        allREPLControllers = @{};
        BOOL isDir = NO;
        [[NSFileManager defaultManager] fileExistsAtPath: url.path isDirectory: &isDir];
        if (isDir) {
            self = [self initWithContentsOfURL: [url URLByAppendingPathComponent: [url.lastPathComponent stringByAppendingPathExtension: @"seproj"]] ofType: SEProjectDocumentType error: outError];
        } else {
            NSLog(@"Opening document of type %@", typeName);
            
            // Set the fileURL:
            if ([typeName isEqualToString: SEProjectDocumentType]) {
                self.fileURL = url;
            } else {
                // Propably some source file, use the parent folder as project name:
                NSURL* folderURL = [url URLByDeletingLastPathComponent];
                NSString* projectFileName = [folderURL.lastPathComponent stringByAppendingPathExtension: @"seproj"];
                self.fileURL = [folderURL URLByAppendingPathComponent: projectFileName];
                
                SESourceItem* singleSourceItem = [self.projectFolderItem childItemWithName: [url lastPathComponent]];
                
                // Open singleSourceItem in the first Tab:
                [self setSourceItem: singleSourceItem forTabIndex: 0];
            }
        }
        
        self.currentLanguage = @"Chibi-Scheme";
        
        return self;
    }
    
    return nil;
}

- (NSUInteger) numberOfEditedSourceItems {
    return 0;
}

- (void) saveAllSourceItems {
    [self.projectFolderItem enumerateAllUsingBlock:^(SESourceItem* item, BOOL* stop) {
        [item saveDocument: self];
    }];
}

- (void) setFileURL:(NSURL *)url {
    if (! [url isEqual: self.fileURL]) {
        [super setFileURL:url];
        projectFolderItem = nil;
    }
}

/**
 * The source item describing the folder containing the project file.
 */
- (SESourceItem*) projectFolderItem {
    if (! projectFolderItem && self.fileURL) {
        projectFolderItem = [[SESourceItem alloc] initWithFileURL: [self.fileURL URLByDeletingLastPathComponent]];
    }
    return projectFolderItem;
}


- (NSString*) defaultDraftName {
    return self.fileURL.lastPathComponent;
}


/**
 *  item may be nil to indicate a removal.
 */
- (void) setSourceItem: (SESourceItem*) item forTabIndex: (NSUInteger) index {
    
    NSParameterAssert([item isTextItem]);
    NSParameterAssert(index<self.sourceTabView.numberOfTabViewItems);
    NSNumber* indexNumber = @(index);
    if (item) {
        NSParameterAssert([item isKindOfClass: [SESourceItem class]]);

        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryBySettingObject: item forKey: indexNumber];
        
        self.uiSettings[@"tabbedSources"][indexNumber.stringValue] = item.longRelativePath;
    } else {
        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryByRemovingObjectForKey: indexNumber];
        [self.uiSettings[@"tabbedSources"] removeObjectForKey: indexNumber.stringValue];
    }
    [self uiSettingsNeedSave];
    
    [self.sourceTabView tabViewItemAtIndex: index].label = item.relativePath;
    
    self.editorController.sourceItem = item;

    

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
    SESourceItem* sourceItem = self.tabbedSourceItems[@([sourceTabView.tabViewItems indexOfObject: sourceTabView.selectedTabViewItem])];
    return sourceItem;
}

- (void) setCurrentSourceItem: (SESourceItem*) sourceItem {
    
    [self setSourceItem: sourceItem forTabIndex: [sourceTabView indexOfSelectedTabViewItem]];
    self.uiSettings[@"selectedSourceTab"] = sourceItem.longRelativePath;
    [self uiSettingsNeedSave];
}

- (NSMutableDictionary*) projectSettings {
    
    if (! projectSettings) {
        NSError* error = nil;
        NSData* projectData = [NSData dataWithContentsOfURL: self.fileURL];
        if (projectData) {
            projectSettings = [NSPropertyListSerialization propertyListWithData: projectData options: NSPropertyListMutableContainers format: NULL error: &error];
        } else {
            projectSettings = [[NSMutableDictionary alloc] init];
        }
    }
    return projectSettings;
}

- (void) saveProjectSettings {
    @synchronized(self) {
        [self.projectSettings writeToURL: self.fileURL atomically: YES];
    }
}

- (void)saveDocument:(id)sender {
    [self saveProjectSettings];
}

- (NSMutableDictionary*) replSettingsForIdentifier: (NSString*) identifier {

    NSMutableDictionary* replSettings = self.projectSettings[@"REPLs"];
    // Create settings dictionary as necessary:
    if (! replSettings) {
        replSettings = [[NSMutableDictionary alloc] init];
        self.projectSettings[@"REPLs"] = replSettings;
    }
    NSMutableDictionary* result = replSettings[identifier];
    if (! result) {
        result = [[NSMutableDictionary alloc] init];
        replSettings[identifier] = result;
    }
    return result;

}

/**
 * Returns the settings for the topmost REPL.
 */
- (NSMutableDictionary*) topREPLSettings {
    NSString* replID = self.replTabView.selectedTabViewItem.identifier;
    return [self replSettingsForIdentifier: replID];
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
        if (! uiSettings[@"tabbedSources"]) {
            uiSettings[@"tabbedSources"] = [[NSMutableDictionary alloc] init];
        }
    }
    return uiSettings;
}

- (void) uiSettingsNeedSave {
    // TODO: save later (on idle?)
    NSError* error = nil;
    NSString* errorString = nil;
    NSData* data = [NSPropertyListSerialization dataFromPropertyList: self.uiSettings format: NSPropertyListBinaryFormat_v1_0 errorDescription: &errorString];
    BOOL done = [data writeToFile: self.uiSettingsPath options: NSDataWritingAtomic error:&error];
    if (! done) {
        NSLog(@"Warning: Unable to write uiSettings to '%@': %@", self.uiSettingsPath, error);
    }
}


- (void) awakeFromNib {
    self.sourceList.doubleAction = @selector(sourceTableDoubleAction:);
}


- (IBAction) sourceTableAction: (id) sender {
    NSLog(@"sourceTableAction.");
    SESourceItem* selectedSourceItem = [self.sourceList itemAtRow: self.sourceList.selectedRow];
    
    if (selectedSourceItem.isTextItem) {
        [self setCurrentSourceItem: selectedSourceItem];
    }
}

- (IBAction)sourceTableDoubleAction: (id) sender {
    NSLog(@"sourceTableDoubleAction.");
    [self sourceTableAction: sender];
    [self.sourceList.window makeFirstResponder: self.editorController.textEditorView];
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
    [self.topREPLController run: sender];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    
    if (tabView == self.replTabView) {
        if (! self.topREPLController.isRunning) {
            NSError* error = nil;
            [self.topREPLController setCommand: @"/usr/local/bin/chibi-scheme"
                                 withArguments: @[]
                              workingDirectory: self.projectFolderItem.absolutePath
                                      greeting: self.languageDictionary[@"WelcomeMessage"]
                                         error: &error];
            
            [self.topREPLController run: self];
            
            if (error) {
                [[NSAlert alertWithError: error] runWithCompletion:^(NSInteger buttonIndex) {
                    [self performSelector: @selector(close) withObject: nil afterDelay: 0.1];
                }];
            }
        }
    } else if (tabView == self.sourceTabView) {
        NSLog(@"selected tab %@", sourceTabView.selectedTabViewItem);
        SESourceItem* sourceItem = self.tabbedSourceItems[sourceTabView.selectedTabViewItem.identifier];
        [self setCurrentSourceItem: sourceItem];
    }
}

- (IBAction) revealInSourceList: (id) sender {
    SESourceItem* currentSourceItem = self.currentSourceItem;
    // Select itemAtPath in source list:
    NSUInteger itemRow = [self.sourceList rowForItem: currentSourceItem];
    if (itemRow != -1) {
        [self.sourceList selectRowIndexes: [NSIndexSet indexSetWithIndex: itemRow]
                     byExtendingSelection: NO];
    }
}


- (void) windowControllerDidLoadNib: (NSWindowController*) aController {
    
    [super windowControllerDidLoadNib: aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    
    // Check, wether the user wants to create a project (from a folder):
    
    self.replTabView.delegate = self;
    [self tabView:self.replTabView didSelectTabViewItem: self.replTabView.selectedTabViewItem];
    
    [self.sourceList setDraggingSourceOperationMask: NSDragOperationLink forLocal: NO];

    // Restore Source Tabs and Selection:
    NSString* sourceTabIdentifier = [self.uiSettings[@"selectedSourceTab"] description];

    NSDictionary* pathsByTabIndex = self.uiSettings[@"tabbedSources"];
    for (NSString* indexString in [pathsByTabIndex allKeys]) {
        NSUInteger tabIndex = [indexString integerValue];
        if (tabIndex < self.sourceTabView.numberOfTabViewItems) {
            NSString* path = pathsByTabIndex[indexString];
            SESourceItem* itemAtPath = [self.projectFolderItem childWithPath: path];
            if ([itemAtPath isTextItem]) {
                [self setSourceItem: itemAtPath forTabIndex: [indexString integerValue]];
                
                if ([sourceTabIdentifier isEqualToString: itemAtPath.longRelativePath]) {
                    // Select tab #tabIndex:
                    [self.sourceTabView selectTabViewItemAtIndex: tabIndex];
                    
                    [self revealInSourceList: self];
                }
            }
        }
    }
    
//    // Make sure the displayed source is selected in source list:
//    NSUInteger row = [sourceList rowForItem: self.currentSourceItem];
//    [sourceList selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
//            byExtendingSelection: NO];
    
    
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


- (BOOL) writeToURL: (NSURL*) absoluteURL ofType: (NSString*) typeName error: (NSError**) outError {
    NSLog(@"Should writeToURL %@ (%@)", absoluteURL, typeName);
    return YES;
}

- (SEREPLController*) replControllerForIdentifier: (NSString*) identifier {
    SEREPLController* result = self.allREPLControllers[identifier];
    if (! result) {
        result = [[SEREPLController alloc] initWithProject:self identifier:identifier];
        NSTabViewItem* item = [self.replTabView tabViewItemAtIndex: [self.replTabView indexOfTabViewItemWithIdentifier: identifier]];
        NSView* itemView = item.view;
        if (! itemView.subviews.count) {
            // Add a copy from the first item:
            itemView = [[self.replTabView tabViewItemAtIndex: 0].view mutableCopy];
            item.view = itemView;
        }
        SEREPLView *replView = [itemView.subviews.lastObject documentView];
        result.replView = replView;
        allREPLControllers = [allREPLControllers dictionaryBySettingObject: result forKey: identifier];
    }
    return result;
}


- (SEREPLController*) topREPLController {
    return [self replControllerForIdentifier: self.replTabView.selectedTabViewItem.identifier];
}

- (IBAction) revealInFinder: (id) sender {
    SESourceItem* selectedItem  = [sourceList itemAtRow: sourceList.selectedRowIndexes.firstIndex];
    NSString* selectedItemPath = selectedItem.absolutePath;
    [[NSWorkspace sharedWorkspace] selectFile: selectedItemPath inFileViewerRootedAtPath: nil];
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
    SEREPLController* replController = self.topREPLController;
    NSLog(@"Evaluating selection: '%@'", evalString);
    [replController evaluateString: evalString];
}

- (IBAction) revertCurrentSourceItemToSaved: (id) sender {
    [self.currentSourceItem revertDocumentToSaved: sender];
}

- (IBAction) saveCurrentSourceItem: (id) sender {
    [self.currentSourceItem saveDocument: sender];
}

- (BOOL) isDocumentEdited {
    __block BOOL edited = [super isDocumentEdited];
    
    if (! edited) {
        [self.projectFolderItem enumerateAllUsingBlock:^(SESourceItem *item, BOOL* stop) {
            NSLog(@"Testing %@", item);
            if ([item isDocumentEdited]) {
                edited = YES;
                *stop = YES;
            }
        }];
    }
    return edited;
}

- (void) canCloseDocumentWithDelegate: (id) delegate shouldCloseSelector: (SEL)shouldCloseSelector contextInfo: (void*) contextInfo {
    NSLog(@"closing sourceItems...");
    [self saveAllSourceItems];
    
    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
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




@end
