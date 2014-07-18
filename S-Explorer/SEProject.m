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
#import "SEImageView.h"

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
@synthesize projectFolderItem = _projectFolderItem;
@synthesize currentSourceItem = _currentSourceItem;

- (id) init {
    if (self = [super init]) {
        self.currentLanguage = @"Clojure"; // TODO: Make configurable
        tabbedSourceItems = @{};
        allREPLControllers = @{};
    }
    return self;
}

- (id) initForURL: (NSURL*) absoluteDocumentURL withContentsOfURL: (NSURL*) absoluteDocumentContentsURL ofType: (NSString*) typeName error: (NSError**) outError {
    return [self initWithContentsOfURL: absoluteDocumentURL ofType: typeName error: outError];
}

    
- (id) initWithContentsOfURL: (NSURL*) url ofType:(NSString*) typeName error:(NSError*__autoreleasing*) errorPtr {
    
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath: url.path isDirectory: &isDir];
    if (isDir) {
        return [self initWithContentsOfURL: [url URLByAppendingPathComponent: [url.lastPathComponent stringByAppendingPathExtension: @"seproj"]] ofType: SEProjectDocumentType error: errorPtr];
    } else {
        
        NSURL* sourceURL = nil;
        
//        if (! [typeName isEqualToString: SEProjectDocumentType]) {
//            // Propably some source file, use the parent folder as project name:
//            NSURL* folderURL = [url URLByDeletingLastPathComponent];
//            NSString* projectFileName = [folderURL.lastPathComponent stringByAppendingPathExtension: @"seproj"];
//            sourceURL = url;
//            url = [folderURL URLByAppendingPathComponent: projectFileName];
//        }
        
        
        if (self = [super initWithContentsOfURL: url ofType: typeName error: errorPtr]) {

            NSLog(@"Opening document of type %@", typeName);
            
            if (sourceURL) {
                // Open sourceURL in the first Tab:
                self.currentSourceItem = [self.projectFolderItem childWithPath: [sourceURL lastPathComponent]];
            }
        
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc addObserver: self selector: @selector(sourceItemEditedStateDidChange:)
                   name: SESourceItemChangedEditedStateNotification
                 object: nil];
            
        }
        return self;
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) sourceItemEditedStateDidChange: (NSNotification*) notification {
    SESourceItem* sourceItem = notification.object;
    //SESourceItem* sourceItemp = [self.sourceList parentForItem: sourceItem];
    NSInteger row = [self.sourceList rowForItem: sourceItem];
    [self.sourceList reloadDataForRowIndexes: [NSIndexSet indexSetWithIndex: row] columnIndexes: [NSIndexSet indexSetWithIndex: 0]];
    //[self.sourceList reloadItem: sourceItem];
}

- (NSUInteger) numberOfEditedSourceItems {
    return 0;
}

- (IBAction) saveAllSourceItems: (id) sender {
    [self.projectFolderItem enumerateAllUsingBlock:^(SESourceItem* item, BOOL* stop) {
        if (item.isDocumentEdited) {
            [item saveDocument: self];
        }
    }];
}

- (void) setFileURL:(NSURL *)url {
    if (! [url isEqual: self.fileURL]) {
        [super setFileURL:url];
        _projectFolderItem = nil;
    }
}

/**
 * The source item describing the folder containing the project file.
 */
- (SESourceItem*) projectFolderItem {
    if (! _projectFolderItem && self.fileURL) {
        _projectFolderItem = [[SESourceItem alloc] initWithFileURL: [self.fileURL URLByDeletingLastPathComponent]];
        self.fileWatcher = [[CDEvents alloc] initWithURLs: @[_projectFolderItem.fileURL]
                                                    block: ^(CDEvents *watcher, CDEvent *event) {
                                                        NSLog(@"fileWatcher reports: %@", event);
                                                        NSString* changedURLString = event.URL.path;
                                                        if (event.flags & (kFSEventStreamEventFlagUserDropped | kFSEventStreamEventFlagKernelDropped)) {
                                                            [_projectFolderItem syncChildrenRecursive: YES];
                                                            [self.sourceList reloadData];
                                                        } else {
                                                            // Find the respective SourceItem and make it syn with the file system:
                                                            NSString* projectPath = [[_projectFolderItem fileURL] path];
                                                            if ([changedURLString hasPrefix: projectPath]) {
                                                                NSString* relativePath = [changedURLString substringFromIndex: projectPath.length];
                                                                SESourceItem* item = [_projectFolderItem childWithPath: relativePath];
                                                                if (item.type == SESourceItemTypeFolder) {
                                                                    BOOL recursive = event.mustRescanSubDirectories;
                                                                    [item syncChildrenRecursive: recursive];
                                                                    [self.sourceList reloadData];
                                                                } else {
                                                                    // TODO: reload file content or display conflict error:
                                                                }
                                                            }
                                                        }
                                                    }
                                                onRunLoop: [NSRunLoop currentRunLoop]
                                     sinceEventIdentifier: 0
                                     notificationLantency: 3.0
                                  ignoreEventsFromSubDirs: NO
                                              excludeURLs: nil
                                      streamCreationFlags: kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagFileEvents];
                            
                            
                            
                            
                            
        self.fileWatcher.ignoreEventsFromSubDirectories = NO;
    }
    return _projectFolderItem;
}


- (NSString*) defaultDraftName {
    return self.fileURL.lastPathComponent;
}


/**
 *  item may be nil to indicate a removal.
 */
- (void) setSourceItem: (SESourceItem*) item forTabIndex: (NSUInteger) index {
    
    NSParameterAssert(item == nil || [item isTextItem]);
    NSParameterAssert(index<self.sourceTabView.numberOfTabViewItems);
    NSNumber* indexNumber = @(index);
    
    if (item) {
        NSParameterAssert([item isKindOfClass: [SESourceItem class]]);
        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryBySettingObject: item forKey: indexNumber];
        
        self.uiSettings[@"tabbedSources"][indexNumber.stringValue] = [self relativePathForSourceItem: item];
    } else {
        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryByRemovingObjectForKey: indexNumber];
        [self.uiSettings[@"tabbedSources"] removeObjectForKey: indexNumber.stringValue];
    }
    [self uiSettingsNeedSave];
    
    [self.sourceTabView tabViewItemAtIndex: index].label = item.name;
    
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
    if (! _currentSourceItem && sourceTabView) {
        NSUInteger selectedTabViewIndex = [sourceTabView indexOfSelectedTabViewItem];
        _currentSourceItem = self.tabbedSourceItems[@(selectedTabViewIndex)];
    }
    return _currentSourceItem;
}

- (void) displayCurrentSourceItem {
    if (sourceList && [self.currentSourceItem isTextItem]) {
        NSUInteger tabNo = [sourceTabView indexOfSelectedTabViewItem];
        [self setSourceItem: self.currentSourceItem forTabIndex: tabNo];
        self.uiSettings[@"selectedSourceTab"] = @(tabNo);
        [self uiSettingsNeedSave];
    }
}


- (void) setCurrentSourceItem: (SESourceItem*) sourceItem {
    _currentSourceItem = sourceItem;
    [self displayCurrentSourceItem];
}

- (void) openSourceItem: (SESourceItem*) item {
    NSUInteger tabIndex = [self indexOfTabViewForItem: item];
    if (tabIndex != NSNotFound) {
        [self.sourceTabView selectTabViewItemAtIndex: tabIndex];
        return;
    }
    
    self.currentSourceItem = item;
    
    [self revealInSourceList: self];
}

- (NSMutableDictionary*) projectSettings {
    
    if (! projectSettings) {
        //[self revertDocumentToSaved: self];
    }
        
    return projectSettings;
}

- (void) saveProjectSettings {
    @synchronized(self) {
        [self.projectSettings writeToURL: self.fileURL atomically: NO];
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
    NSURL* uiFolderURL = self.projectFolderItem.fileURL;
    NSString* uiFilePath = [uiFolderURL.path stringByAppendingPathComponent: @".UISettings.plist"];
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
    NSAssert(! errorString, @"Problem serializing %@: %@", self.uiSettings, errorString);
    BOOL done = [data writeToFile: self.uiSettingsPath options: NSDataWritingAtomic error:&error];
    if (! done) {
        NSLog(@"Warning: Unable to write uiSettings to '%@': %@", self.uiSettingsPath, error);
    }
}


- (void) awakeFromNib {
    self.sourceList.doubleAction = @selector(sourceTableDoubleAction:);
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
    
    if (! [self.currentLanguage isEqualToString: language]) {
        currentLanguage = language;
        NSDictionary* langDict = self.languageDictionary;
        NSAssert(langDict, @"No language definition for %@ in info.plist.", language);
        
        [self checkLibraryAlias];
    }
}

- (NSDictionary*) languageDictionary {
    NSDictionary* languageDictionaries = [[NSBundle mainBundle] infoDictionary][@"LanguageSupport"];
    return languageDictionaries[self.currentLanguage];
}


- (void) startREPLServerAsNeccessary {
    
    if (! self.nREPL.task.isRunning) {
        if (! self.nREPL) {
            NSMutableDictionary* settings = [self.languageDictionary mutableCopy];
            [settings addEntriesFromDictionary: self.topREPLSettings];
            [settings setObject: [self.fileURL.path stringByDeletingLastPathComponent] forKey: @"WorkingDirectory"];
            
            self.topREPLController.replView.interpreterString = @"Starting nREPL Server...";
            
            _nREPL = [[SEnREPL alloc] initWithSettings: settings];
            [_nREPL startWithCompletionBlock:^(SEnREPL *repl, NSError *error) {
                NSLog(@"%@ startup completed (with error %@), listening on port #%ld", repl, error, repl.port);
                if (! error) {
                    // Connect clients:
                    [self.topREPLController.replView appendInterpreterString:  @"Connecting to nREPL Server..."];
                    self.topREPLController.greeting = self.languageDictionary[@"WelcomeMessage"];
                    self.topREPLController.replView.prompt = self.languageDictionary[@"Prompt"];
                    
                    [self.topREPLController connectWithBlock:^(SEnREPLConnection *connection, NSError *error) {
                        if (error) {
                            [self.topREPLController.replView appendInterpreterString: [NSString stringWithFormat: @"\nConnect failed: %@", error]];
                        }
                        
                        NSString* keywordExpression = self.languageDictionary[@"Keywords"][@"DynamicExpression"];
                        if (keywordExpression.length) {
                            [connection evaluateExpression: keywordExpression
                                           completionBlock:^(NSDictionary *partialResult) {
                                               NSString* allKeywordsString = [partialResult[@"value"] mutableCopy];
                                               if ([allKeywordsString hasPrefix: @"("] && [allKeywordsString hasSuffix: @")"]) {
                                                   allKeywordsString = [allKeywordsString substringWithRange: NSMakeRange(1, allKeywordsString.length-2)];
                                               
                                                   // Convert List (Expression) into String-Array:
                                                   //NSOrderedSet* allKeywords = [self.editorController.keywords];
                                                   
                                                   NSMutableArray* allKeywords = [self.editorController.defaultKeywords mutableCopy];
                                                   [allKeywords addObjectsFromArray: [allKeywordsString componentsSeparatedByString: @" "]];
                                                   [allKeywords sortUsingSelector: @selector(compare:)];
                                                   
                                                   NSOrderedSet* orderedKeywords = [NSOrderedSet orderedSetWithArray: allKeywords];
                                                   
                                                   NSLog(@"'Partial' keyword result: %@", orderedKeywords);
                                                   
                                                   // Copy the set of keywords to editor and repl view:
                                                   self.editorController.textView.keywords = orderedKeywords;
                                                   self.topREPLController.replView.keywords = orderedKeywords;
                                               
                                                   //                                               id allSessionIDs = [connection allSessionIDs];
                                                   //                                               NSLog(@"allSessionIDs: %@", allSessionIDs);
                                               }
                                           }];
                        }
                    }];
                }
            }];
        }
        
        
//        if (_nREPL.task. error) {
//            [[NSAlert alertWithError: error] runWithCompletion:^(NSInteger buttonIndex) {
//                [self performSelector: @selector(close) withObject: nil afterDelay: 0.1];
//            }];
//        }
    }
}

- (void) tabView: (NSTabView*) tabView didSelectTabViewItem: (NSTabViewItem*) tabViewItem {
    
    if (tabView == self.replTabView) {
        SEREPLViewController* replController = self.topREPLController;
        if (self.nREPL.port && ! replController.evalConnection.socket.isConnected) {
            [replController connectWithBlock:^(SEnREPLConnection *connection, NSError *error) {
                
            }];
        }
    } else if (tabView == self.sourceTabView) {
        NSLog(@"selected tab %@", sourceTabView.selectedTabViewItem);
        SESourceItem* sourceItem = self.tabbedSourceItems[sourceTabView.selectedTabViewItem.identifier];
        [self setCurrentSourceItem: sourceItem];
    }
}

- (NSUInteger) indexOfTabViewForItem: (SESourceItem*) item {
    for (NSNumber* tabNo in self.tabbedSourceItems) {
        if ([self.tabbedSourceItems[tabNo] isEqual: item]) {
            return tabNo.integerValue;
        }
    }
    return NSNotFound;
}

- (void) expandSourceListToItem: (SESourceItem*) item {
    if (! item) return;
    
    [self expandSourceListToItem: item.parent];
    [self.sourceList expandItem: item];
}


- (void) windowControllerDidLoadNib: (NSWindowController*) aController {
    
    [super windowControllerDidLoadNib: aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    self.editorController.defaultKeywords = self.languageDictionary[@"Keywords"][@"StaticList"];

    // Check, wether the user wants to create a project (from a folder):
    
    self.replTabView.delegate = self;
    
    // Fake a tab selection:
    [self tabView:self.replTabView didSelectTabViewItem: self.replTabView.selectedTabViewItem];
    
    [self.sourceList setDraggingSourceOperationMask: NSDragOperationLink forLocal: NO];

    // Restore Source Tabs and Selection:

    NSDictionary* pathsByTabIndex = self.uiSettings[@"tabbedSources"];
    for (NSString* indexString in [pathsByTabIndex allKeys]) {
        NSUInteger tabIndex = [indexString integerValue];
        if (tabIndex < self.sourceTabView.numberOfTabViewItems) {
            NSString* path = pathsByTabIndex[indexString];
            SESourceItem* itemAtPath = [self.projectFolderItem childWithPath: path];
            if ([itemAtPath isTextItem]) {
                [self setSourceItem: itemAtPath forTabIndex: tabIndex];
            }
        }
    }
    
    NSUInteger selectedSourceTabIndex = 0;
    @try {
        selectedSourceTabIndex = [self.uiSettings[@"selectedSourceTab"] unsignedIntegerValue];
    }
    @catch (NSException *exception) {
    }
    [self.sourceTabView selectTabViewItemAtIndex: selectedSourceTabIndex];
    if (! self.currentSourceItem) {
        // If no sourceItem is selected in the current tab, select the first text item
        __block SESourceItem* firstItem;
        [self.projectFolderItem enumerateAllUsingBlock:^(SESourceItem *item, BOOL *stop) {
            if ([item isTextItem]) {
                *stop = YES;
                firstItem = item;
            }
        }];
        self.currentSourceItem = firstItem;
    }
    [self displayCurrentSourceItem];
    
    
//    // Make sure the displayed source is selected in source list:
//    NSUInteger row = [sourceList rowForItem: self.currentSourceItem];
//    [sourceList selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
//            byExtendingSelection: NO];
    
    
    for (NSString* path in [self.uiSettings[@"expandedFolders"] allKeys]) {
        SESourceItem* item = [self sourceItemForRelativePath: path];
        [self.sourceList expandItem: item];
    }
    
    
    
    [self revealInSourceList: nil];
    
    
    [self startREPLServerAsNeccessary];
}

+ (BOOL) autosavesInPlace {
    return YES;
}

- (NSData*) dataOfType: (NSString*) typeName error: (NSError**) errorPtr {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
//    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
//    @throw exception;
//    return nil;
    
    return [NSPropertyListSerialization dataWithPropertyList: projectSettings format: NSPropertyListXMLFormat_v1_0 options: 0 error: errorPtr];
}

- (BOOL) readFromData: (NSData*) projectData ofType: (NSString*) typeName error: (NSError**) errorPtr {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
//    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
//    @throw exception;
    
    if (projectData) {
        projectSettings = [NSPropertyListSerialization propertyListWithData: projectData options: NSPropertyListMutableContainers format: NULL error: errorPtr];
    }
    if (!projectSettings) {
        projectSettings = [[NSMutableDictionary alloc] init];
    }
    
    return YES;
}


- (BOOL) writeToURL: (NSURL*) absoluteURL ofType: (NSString*) typeName error: (NSError**) outError {
    NSLog(@"Should writeToURL %@ (%@)", absoluteURL, typeName);
    return YES;
}

- (SEREPLViewController*) replControllerForIdentifier: (NSString*) identifier {
    SEREPLViewController* result = self.allREPLControllers[identifier];
    if (! result) {
        result = [[SEREPLViewController alloc] initWithProject:self identifier:identifier];
        NSTabViewItem* item = [self.replTabView tabViewItemAtIndex: [self.replTabView indexOfTabViewItemWithIdentifier: identifier]];
        NSView* itemView = item.view;
        if (! itemView.subviews.count) {
            // Add a copy from the first item:
            itemView = [[self.replTabView tabViewItemAtIndex: 0].view mutableCopy];
            item.view = itemView;
        }
        SEREPLView *replView = [itemView.subviews.lastObject documentView];
        result.textView = replView;
        allREPLControllers = [allREPLControllers dictionaryBySettingObject: result forKey: identifier];
    }
    return result;
}


- (SEREPLViewController*) topREPLController {
    return [self replControllerForIdentifier: self.replTabView.selectedTabViewItem.identifier];
}

#pragma mark - Convert between relative paths and sourceItems

- (NSString*) relativePathForSourceItem: (SESourceItem*) sourceItem {
    NSString* path = sourceItem.fileURL.absoluteString;
    NSString* rootPath = self.projectFolderItem.fileURL.absoluteString;
    NSString* relativePath = [path substringFromIndex: rootPath.length];
    return relativePath;
}


- (SESourceItem*) sourceItemForRelativePath: (NSString*) path {
    return [self.projectFolderItem childWithPath: path];
}


#pragma mark - Actions


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
    [self.sourceList.window makeFirstResponder: self.editorController.textView];
}

- (IBAction) runProject: (id) sender {
    [self.topREPLController run: sender];
}

- (void) replServerDidStart: (SEnREPL*) repl {
    if (repl.task.isRunning) {
        NSLog(@"replServerDidStart: %@", repl);
    }
}

- (IBAction) revealInSourceList: (id) sender {
    SESourceItem* currentSourceItem = self.currentSourceItem;
    
    [self expandSourceListToItem: currentSourceItem];
    // Select itemAtPath in source list:
    NSUInteger itemRow = [self.sourceList rowForItem: currentSourceItem];
    
    if (itemRow != -1) {
        [self.sourceList selectRowIndexes: [NSIndexSet indexSetWithIndex: itemRow]
                     byExtendingSelection: NO];
        return;
    }
    NSLog(@"Unable to reveal %@ in source list.", currentSourceItem);
}

- (IBAction) revealInFinder: (id) sender {
    SESourceItem* selectedItem  = [sourceList itemAtRow: sourceList.selectedRowIndexes.firstIndex];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs: @[selectedItem.fileURL]];
}

- (IBAction) evaluateSelection: (id) sender {
    
    NSRange evalRange = self.editorController.textView.selectedRange;
    if (! evalRange.length) {
        evalRange = [self.editorController topLevelExpressionContainingLocation: evalRange.location];
        if (! evalRange.length) {
            NSBeep();
            return;
        }
    }
    
    NSString* evalString = [self.editorController.textView.string substringWithRange:evalRange];
    SEREPLViewController* replController = self.topREPLController;
    NSLog(@"Evaluating selection: '%@'", evalString);
    [replController.replView  moveToEndOfDocument: sender];
    [replController.replView setCommand: evalString];
    [replController sendCurrentCommand];
//    [replController.replView insertText: evalString];
//    [replController performSelector: @selector(insertNewline:) withObject: sender afterDelay: 0.1];
}

- (IBAction) revertCurrentSourceItemToSaved: (id) sender {
    [self.currentSourceItem revertDocumentToSaved: sender];
}

- (IBAction) saveCurrentSourceItem: (id) sender {
    
    NSLog(@"Saving current source item %@ to disk.", self.currentSourceItem);
    
    [self.currentSourceItem saveDocument: sender];
}

/* 
 * The project is edited, if the project file or any of the source items has unsaved changes.
 */
- (BOOL) isDocumentEdited {
    __block BOOL edited = [super isDocumentEdited];
    
    if (! edited) {
        [self.projectFolderItem enumerateAllUsingBlock:^(SESourceItem *item, BOOL* stop) {
            //NSLog(@"Testing %@", item);
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
    [self saveAllSourceItems: nil];
    
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
    
    return [item name];
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    self.uiSettings[@"expandedFolders"][[self relativePathForSourceItem: item]] = @YES;
    [self uiSettingsNeedSave];
    return YES;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    [self.uiSettings[@"expandedFolders"] removeObjectForKey: [self relativePathForSourceItem: item]];
    [self uiSettingsNeedSave];
    return YES;
}


- (BOOL) outlineView: (NSOutlineView*) outlineView writeItems: (NSArray*) items toPasteboard:(NSPasteboard *)pboard {
    // Set the pasteboard for File promises only
    [pboard declareTypes: @[NSURLPboardType] owner:self];
    
    // The pasteboard must know the type of files being promised:
    
    NSMutableSet* urlStrings = [NSMutableSet set];
    for (SESourceItem* item in items) {
        NSString* urlString = item.fileURL.absoluteString;
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

- (NSView*) outlineView: (NSOutlineView*) outlineView viewForTableColumn: (NSTableColumn*) tableColumn item:(SESourceItem*) item {
    
    NSTableCellView *result = [outlineView makeViewWithIdentifier: [tableColumn identifier] owner: self];

    NSURL* fileURL = [item fileURL];
    result.textField.stringValue = [[fileURL filePathURL] lastPathComponent];
    NSImage* image;
    
    if (item.type == SESourceItemTypeFolder) {
        image = [NSImage imageNamed: @"folder"];
    } else {
        NSString* path = fileURL.path;
        image = [[NSWorkspace sharedWorkspace] iconForFile: path];
    }
    result.imageView.image = image;
    BOOL isItemEdited = [item isDocumentEdited];
    ((SEImageView*)result.imageView).highlighted = isItemEdited;
    
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

- (NSPrintOperation*) printOperationWithSettings: (NSDictionary*) printSettings error: (NSError **)outError {
    
    // Minimalistic printing support:
    NSPrintInfo * printInfo = [self printInfo];
    NSPrintOperation * printOp = [NSPrintOperation printOperationWithView: self.editorController.textView printInfo: printInfo];
    return printOp;
}




@end
