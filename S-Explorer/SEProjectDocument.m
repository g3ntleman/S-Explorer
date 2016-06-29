
//
//  SEProjectDocument
//  S-Explorer
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import "SEProjectDocument.h"
#import "NSAlert+OPBlocks.h"
#import "SESourceItem.h"
#import "NSDictionary+OPImmutablility.h"
#import "NoodleLineNumberView.h"
#import "OPUtilityFunctions.h"
#import "OPTabView.h"
#import "SEImageView.h"
#import "NSTableView+OPSelection.h"
#import "SCEvents.h"
#import "SCEvent.h"
#import "SETarget.h"
#import "NSUserDefaults+OPMutability.h"

@interface SEProjectDocument ()
@property (readonly) NSString* uiSettingsPath;
@property (strong) NSString* javaClasspath;
@property (strong, atomic) SEREPLServer* replServer;
@property (strong, atomic) SEREPLConnection* toolConnection;


@end

@implementation SEProjectDocument {
    NSMutableDictionary* _settings;
    BOOL _settingsNeedSave;
    NSDictionary* savedSplitViewPositions;
}

@synthesize tabbedSourceItems;
@synthesize allREPLControllers;
@synthesize sourceTabView;
@synthesize sourceList;
@synthesize currentLanguage;
@synthesize projectFolderItem = _projectFolderItem;
@synthesize currentSourceItem = _currentSourceItem;
@synthesize javaClasspath = _javaClasspath;

- (id) init {
    if (self = [super init]) {
        self.currentLanguage = @"Clojure"; // TODO: Make configurable

        tabbedSourceItems = @{};
        allREPLControllers = @{};
        self.toolConnection = [[SEREPLConnection alloc] init]; // initialize early, so it can buffer requests!
    }
    return self;
}

- (id) initForURL: (NSURL*) absoluteDocumentURL withContentsOfURL: (NSURL*) absoluteDocumentContentsURL ofType: (NSString*) typeName error: (NSError**) outError {
    return [self initWithContentsOfURL: absoluteDocumentURL ofType: typeName error: outError];
}

    
- (id) initWithContentsOfURL: (NSURL*) url ofType:(NSString*) typeName error:(NSError*__autoreleasing*) errorPtr {
    
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath: url.path isDirectory: &isDir];
    //NSAssert(! isDir, @"Try to open document of type '%@' from directory at '%@'.", typeName, url);
    NSURL* sourceURL = nil;
    
    if (! isDir) {
        // Propably some source file, use the parent folder as project name:
        sourceURL = url;
        url = [url URLByDeletingLastPathComponent];
    }
    
    
    if (self = [super initWithContentsOfURL: url ofType: typeName error: errorPtr]) {
        
        NSLog(@"Opening document of type %@", typeName);
        
        if (sourceURL) {
            // Open sourceURL in the first Tab:
            self.currentSourceItem = [self.projectFolderItem childWithPath: [sourceURL lastPathComponent]];
            [self toggleSourceOnlyMode: self];
        }
        
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc addObserver: self selector: @selector(sourceItemEditedStateDidChange:)
                   name: SESourceItemChangedEditedStateNotification
                 object: nil];
        
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (NSMutableDictionary*) settings {
    if (! _settings) {
        NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
        NSString* fileKey = self.projectFileItem.fileURL.fileReferenceURL.absoluteString;
        if (! fileKey) {
            return nil; // no project file, no settings
        }
        NSDictionary* projectSettings = [ud objectForKey: [@"Project@" stringByAppendingString: fileKey]];
        if (! projectSettings) {
            projectSettings = [[NSMutableDictionary alloc] init];
        }
        // Cache a deep mutable copy:
        _settings =  CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (CFDictionaryRef)projectSettings, kCFPropertyListMutableContainers));
    }
    return _settings;
}

- (NSString*) javaClasspath {
    if (!_javaClasspath) {
        NSDictionary* projectDefaults = self.settings[@"JavaClassPath"];
        if (projectDefaults.count) {
            NSNumber* modTime = projectDefaults[@"Time"];
            NSDate* pathDate = [NSDate dateWithTimeIntervalSince1970: [modTime integerValue]];
            NSDate* projectFileDate = self.projectFileItem.fileModificationDate;
            if ([projectFileDate laterDate: pathDate] == pathDate) {
                _javaClasspath = projectDefaults[@"Path"];
                if (! [_javaClasspath isKindOfClass: [NSString class]]) {
                    _javaClasspath = nil;
                }
            }
        }
    }
    return _javaClasspath;
}

- (void) setJavaClasspath: (NSString*) javaClasspath {
    
    if (_javaClasspath != javaClasspath) {
        _javaClasspath = javaClasspath;
        [self.settings setObject: @{@"Time": @((NSInteger)[[NSDate date] timeIntervalSince1970]),
                                      @"Path": javaClasspath} forKey: @"JavaClassPath"];
        [self settingsNeedSave];
    }
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

    [self saveDocument: sender];
}

- (IBAction) newFile: (id) sender {
    
    NSError* error = nil;
    NSString* filename = @"Untitled.clj";
    NSURL* newURL = [self.projectFolderItem.fileURL URLByAppendingPathComponent: filename];
    [@"" writeToURL: newURL atomically: NO encoding: NSUTF8StringEncoding error: &error];
    [self.projectFolderItem syncChildrenRecursive: NO];
    [self.sourceList reloadData];
    SESourceItem* newSourceItem = [self.projectFolderItem childWithPath: filename];
    [self.sourceList selectRowIndex: [self.sourceList rowForItem: newSourceItem]];
}

- (IBAction) toggleSourceOnlyMode: (id) sender {
    
//    if ([self.verticalSplitView isSubviewCollapsed: self.verticalSplitView.subviews.firstObject]) {
//        [self.verticalSplitView.subviews.firstObject setHidden: NO];
//        [self.horizontalSplitView.subviews.lastObject setHidden: NO];
//    } else {
//        [self.verticalSplitView.subviews.firstObject setHidden: YES];
//        [self.horizontalSplitView.subviews.lastObject setHidden: YES];
//    }
    
    
    if (savedSplitViewPositions.count) {
        // restore savedSplitViewPositions:
        NSNumber* filesPaneWidth = savedSplitViewPositions[@"filesPaneWidth"];
        NSNumber* debugPaneHeight = savedSplitViewPositions[@"debugPaneHeight"];
        
        [self.verticalSplitView setPosition: filesPaneWidth.floatValue ofDividerAtIndex: 0];
        [self.horizontalSplitView setPosition: self.horizontalSplitView.frame.size.height - debugPaneHeight.floatValue - self.horizontalSplitView.dividerThickness ofDividerAtIndex: 0];
        
        savedSplitViewPositions = nil;
    } else {
        // store savedSplitViewPositions:
        
        NSNumber* filesPaneWidth = @([self.verticalSplitView.subviews.firstObject frame].size.width);
        NSNumber* debugPaneHeight =  @([self.horizontalSplitView.subviews.lastObject frame].size.height);

        savedSplitViewPositions = @{@"filesPaneWidth": filesPaneWidth,
                                    @"debugPaneHeight": debugPaneHeight};
        
        // Collapse left and lower pane:
        [self.verticalSplitView setPosition: 0.0 ofDividerAtIndex: 0];
        [self.horizontalSplitView setPosition: 10000.0 ofDividerAtIndex: 0];
    }
    //[self.verticalSplitView adjustSubviews];
    //[self.horizontalSplitView adjustSubviews];
}

- (BOOL) splitView: (NSSplitView*) splitView canCollapseSubview: (NSView*) subview {
    if (splitView == self.verticalSplitView) {
        // NSLog(@"Can collapse %@", subview);
        return subview != self.horizontalSplitView.superview;
    }
    return YES;
}

- (CGFloat) splitView: (NSSplitView*) splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (splitView == self.verticalSplitView) {
        return proposedMinimumPosition + 170.0;
    }
    
    return proposedMinimumPosition + 50.0;
}

/*
 * Controls the minimum size of the right subview (or lower subview in a horizonal NSSplitView)
 */
- (CGFloat) splitView: (NSSplitView*) splitView constrainMaxCoordinate: (CGFloat)proposedMaximumPosition ofSubviewAt: (NSInteger) dividerIndex {
    if (splitView == self.verticalSplitView) {
        return proposedMaximumPosition - 450.0;
    }
    return proposedMaximumPosition - 80.0;
}



- (void) setFileURL:(NSURL *)url {
    BOOL isDir = NO;
    NSParameterAssert(url.hasDirectoryPath && [[NSFileManager defaultManager] fileExistsAtPath: url.path isDirectory: &isDir] && isDir);
    if (! [url isEqual: self.fileURL]) {
        [super setFileURL:url];
        _projectFolderItem = nil;
        [self reloadSourceList];
    }
}

// Reload Source List (mostly) without loosing selection:
- (void) reloadSourceList {
    NSOutlineView* slist = self.sourceList;
    id selectedItem = [slist itemAtRow: slist.selectedRow];
    [self.sourceList reloadData];
    NSInteger rowToSelect = [slist rowForItem: selectedItem];
    if (rowToSelect != NSNotFound) {
        [slist selectRowIndexes: [NSIndexSet indexSetWithIndex: [self.sourceList rowForItem: selectedItem]]
           byExtendingSelection: NO];
    }
}

- (void) pathWatcher: (SCEvents*) pathWatcher eventOccurred: (SCEvent*) event {
    
    SCEventFlags flags = event.eventFlags;
    
    // Ignore some event types:
//    if (flags & SCEventStreamEventFlagItemChangeOwner) {
//        return;
//    }
    
    NSString* pathChanged = event.eventPath;

    // Ignore all dotfiles:
    if ([[pathChanged lastPathComponent] hasPrefix: @"."]) {
        return;
    }
    
    NSLog(@"File Event occured: %@", event);
    
    SESourceItem* item = self.projectFolderItem;
    
    NSString* projectPath = [[_projectFolderItem fileURL] path];
    if ([pathChanged hasPrefix: projectPath]) {
        if (pathChanged.length > projectPath.length) {
            NSString* relativePath = [pathChanged substringFromIndex: projectPath.length];
            while (! (item = [_projectFolderItem childWithPath: relativePath]) && relativePath.length) {
                relativePath = [relativePath stringByDeletingLastPathComponent]; // walk up!
            }
        }
    }
    
    if (item) {
        
        if ((flags & SCEventStreamEventFlagItemIsDir) || (flags & (SCEventStreamEventFlagItemRemoved | SCEventStreamEventFlagItemCreated | SCEventStreamEventFlagItemRenamed))) {
            if (flags & SCEventStreamEventFlagItemIsFile) {
                item = item.parent;
            }
            
            [item syncChildrenRecursive: flags & SCEventStreamEventFlagMustScanSubDirs];
            [self.sourceList reloadItem: item reloadChildren: YES];
        } else {
            // File or Symlink
            NSLog(@"File %@ has changed.", item);

        }
        
        
//        if (item.isTextItem && ! (flags & (SCEventStreamEventFlagItemRemoved | SCEventStreamEventFlagItemCreated | SCEventStreamEventFlagItemRenamed))) {
//            NSLog(@"Textfile %@ has changed.", item);
//            [self.sourceList reloadItem: item];
//        } else {
//            [item syncChildrenRecursive: flags & SCEventStreamEventFlagMustScanSubDirs];
//            [self reloadSourceList];
//        }
    }
    
//    if (self.currentSourceItem.content != self.editorController.textView.textStorage) {
//        self.editorController.textView.layoutManager.textStorage = self.currentSourceItem.content;
//    }
}


/**
 * The source item describing the folder containing the project file.
 */
- (SESourceItem*) projectFolderItem {
    if (! _projectFolderItem && self.fileURL) {
        
        // Create source item from fileURL on demand:
        _projectFolderItem = [[SESourceItem alloc] initWithContentsOfURL: self.fileURL ofType: nil error: nil];
        
        self.pathWatcher = [[SCEvents alloc] init];
        [self.pathWatcher setIgnoreEventsFromSubDirs: NO];
        self.pathWatcher.delegate = self;
        [self.pathWatcher startWatchingPaths: @[_projectFolderItem.fileURL.path]];
        
        NSLog(@"%@", [self.pathWatcher streamDescription]);

        
/*
        self.fileWatcher = [[CDEvents alloc] initWithURLs: @[_projectFolderItem.fileURL]
                                                    block: ^(CDEvents *watcher, CDEvent *event) {
                                                        NSString* changedURLString = event.URL.path;
                                                        if (event.flags & (kFSEventStreamEventFlagUserDropped | kFSEventStreamEventFlagKernelDropped)) {
                                                            [_projectFolderItem syncChildrenRecursive: YES];
                                                            [self reloadSourceList];
                                                        } else {
                                                            if ([changedURLString.lastPathComponent hasPrefix: @"."]) {
                                                                return; // skip hidden files
                                                            }
                                                            if (YES || event.flags & (kFSEventStreamEventFlagItemCreated | kFSEventStreamEventFlagItemRemoved | kFSEventStreamEventFlagItemModified)) {
                                                                NSLog(@"fileWatcher reports: %@", event);
                                                                    // Find the respective SourceItem and make it syn with the file system:
                                                                    NSString* projectPath = [[_projectFolderItem fileURL] path];
                                                                    if ([changedURLString hasPrefix: projectPath]) {
                                                                        SESourceItem* item = _projectFolderItem;
                                                                        NSString* relativePath = @"";
                                                                        if (changedURLString.length > projectPath.length) {
                                                                            relativePath = [changedURLString substringFromIndex: projectPath.length];
                                                                            item = [_projectFolderItem childWithPath: relativePath];
                                                                        }
                                                                        if (! item) {
                                                                            NSLog(@"Oops! No item found for path '%@'. Ignoring.", relativePath); // TODO!!
                                                                            return;
                                                                        }
                                                                        if (item.type == SESourceItemTypeFolder) {
                                                                            BOOL recursive = event.mustRescanSubDirectories;
                                                                            [item syncChildrenRecursive: recursive];
                                                                            [self reloadSourceList];
                                                                        } else {
                                                                            // TODO: reload file content or display conflict error:
                                                                            NSLog(@"Content of file %@ changed.", changedURLString);
                                                                            if (item.isOpen && ! item.isDocumentEdited) {
                                                                                [item revertToContentsOfURL: event.URL ofType: item.fileType error: NULL];
                                                                            }
                                                                        }
                                                                    }

                                                            }
                                                        }
                                                    }
                                                onRunLoop: [NSRunLoop currentRunLoop]
                                     sinceEventIdentifier: 0
                                     notificationLantency: 2.0
                                  ignoreEventsFromSubDirs: NO
                                              excludeURLs: nil
                                      streamCreationFlags: kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagIgnoreSelf 
 //| kFSEventStreamCreateFlagFileEvents
        ];
        
        self.fileWatcher.ignoreEventsFromSubDirectories = NO;
        */
    }
    return _projectFolderItem;
}

- (SESourceItem*) projectFileItem {
    return [self.projectFolderItem childWithPath: @"project.clj"];
}


- (NSString*) defaultDraftName {
    return self.fileURL.lastPathComponent;
}

- (void) updateKeywords {
    
    SESourceEditorController* editor = self.editorController;
    NSString* code = editor.sourceItem.contents.string;
    //
    [self.toolConnection sendExpression: [NSString stringWithFormat: @"(do %@ (replicant.util/map-map-vals (merge  (ns-map *ns*) (comment ns-interns *ns*)) replicant.util/var-namespace))", code]
    // [self.toolConnection sendExpression: [NSString stringWithFormat: @"(do %@ (merge (ns-interns *ns*) (ns-map *ns*)))", code]
                                timeout: 20.0
                             completion: ^(NSDictionary* evalResult) {
                                 NSDictionary* map = evalResult[@"result"];
                                 if ([map isKindOfClass: [NSDictionary class]]) {
                                     //NSLog(@"Result evaluating ns: '%@'", map);
                                     editor.sortedKeywords = [NSOrderedSet orderedSetWithArray: [map.allKeys sortedArrayUsingSelector: @selector(compare:)]];
                                 } else {
                                     NSLog(@"Error Result: %@", evalResult);
                                 }
                             }];
    
}

/**
 *  item may be nil to indicate a removal.
 */
- (void) setSourceItem: (SESourceItem*) item forTabIndex: (NSUInteger) index {

    NSNumber* indexNumber = @(index);

    if (self.tabbedSourceItems[indexNumber] == item) {
        return; // item already set
    }
    
    NSParameterAssert(item == nil || [item isTextItem]);
    NSParameterAssert(index<self.sourceTabView.numberOfTabViewItems);
    
    if (item) {
        NSParameterAssert([item isKindOfClass: [SESourceItem class]]);
        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryBySettingObject: item forKey: indexNumber];
        
        self.uiSettings[@"tabbedSources"][indexNumber.stringValue] = [self relativePathForSourceItem: item];
    } else {
        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryByRemovingObjectForKey: indexNumber];
        [self.uiSettings[@"tabbedSources"] removeObjectForKey: indexNumber.stringValue];
    }
    [self settingsNeedSave];
    
    [self.sourceTabView tabViewItemAtIndex: index].label = item.name;
    
    self.editorController.sourceItem = item;
    
    
    [self updateKeywords];
    
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

- (NSString*) windowNibName {
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return [[self class] description];
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
        [self settingsNeedSave];
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


- (void) saveDocument: (id) sender {
    
    [self.projectFolderItem enumerateAllUsingBlock: ^(SESourceItem* item, BOOL* stop) {
        if (item.isDocumentEdited) {
            [item saveDocument: self];
        }
    }];
}

- (NSMutableDictionary*) replSettingsForIdentifier: (NSString*) identifier {

    NSMutableDictionary* replSettings = nil; //self.projectSettings[@"REPLs"];
    // Create settings dictionary as necessary:
    if (! replSettings) {
        replSettings = [[NSMutableDictionary alloc] init];
        // self.projectSettings[@"REPLs"] = replSettings;
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

- (NSMutableDictionary*) uiSettings {
    NSMutableDictionary* uiSettings = [self.settings mutableDictionaryForKey: @"UISettings"];
    return uiSettings;
}

- (void) saveSettings {
    
    if (_settingsNeedSave) {
        
        NSString* fileKey = self.projectFileItem.fileURL.fileReferenceURL.absoluteString;
        if (fileKey) {
            [[NSUserDefaults standardUserDefaults] setObject: self.settings
                                                      forKey: [@"Project@" stringByAppendingString: fileKey]];
        }
    }
    _settingsNeedSave = NO;
}

- (void) settingsNeedSave {
    
    if (! _settingsNeedSave) {
        // TODO: save later (on idle?)
        _settingsNeedSave = YES;
    
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self saveSettings];
        });
    }
}


- (void) awakeFromNib {
    self.sourceList.doubleAction = @selector(sourceTableDoubleAction:);
    self.sourceList.indentationMarkerFollowsCell = NO;
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


- (void) startREPLServerWithCompletion: (SEREPLServerCompletionBlock) block {
    
    if (! self.replServer.task.isRunning && self.fileURL) {
        if (! self.replServer) {
            NSMutableDictionary* settings = [self.languageDictionary mutableCopy];
            [settings addEntriesFromDictionary: self.topREPLSettings];
            [settings setObject: [self.fileURL.path stringByDeletingLastPathComponent] forKey: @"WorkingDirectory"];
            [settings setObject: self.javaClasspath forKey: @"JavaClassPath"];
            
            //self.topREPLController.replView.interpreterString = @"Starting nREPL Server...";
            
            //_target = [[SETarget alloc] initWithSettings: settings];
            self.replServer = [[SEREPLServer alloc] initWithSettings: settings];
            
        }
        [self.replServer startWithCompletion: block];
    }
    
   /* Code to start an interactive user repl:
    
    [_replServer startWithCompletionBlock: ^(SEREPLServer* repl, NSError* error) {
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

    
//        if (_nREPL.task. error) {
//            [[NSAlert alertWithError: error] runWithCompletion:^(NSInteger buttonIndex) {
//                [self performSelector: @selector(close) withObject: nil afterDelay: 0.1];
//            }];
//        }
    */
}

- (void) tabView: (NSTabView*) tabView didSelectTabViewItem: (NSTabViewItem*) tabViewItem {
    
    if (tabView == self.replTabView) {
        SEREPLViewController* replController = self.topREPLController;
        if (self.replServer.port && ! replController.evalConnection.socket.isConnected) {
            [replController connectWithBlock:^(SEREPLConnection *connection, NSError *error) {
                
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
    
    self.editorController.defaultKeywords = [NSSet setWithArray: self.languageDictionary[@"Keywords"][@"StaticList"]];
    
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
            SESourceItem* itemAtPath = [self sourceItemForRelativePath: path];
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
    
    @try {
        NSArray* expandedFolders = [[self.uiSettings mutableDictionaryForKey: @"expandedFolders"] allKeys];
        // Make sure, folders are expanded in the right order (parents first):
        expandedFolders = [expandedFolders sortedArrayUsingSelector: @selector(length)];
        //NSLog(@"Settings: expandedFolders = %@", expandedFolders);
        for (NSString* path in expandedFolders) {
            SESourceItem* item = [self sourceItemForRelativePath: path];
            [self.sourceList expandItem: item];
        }
    } @catch (NSException *exception) {
        NSLog(@"Error Restoring expanded folders: %@. Ignored.", exception);
    }

    
    [self revealInSourceList: nil];
    
    // Check, if we have a project file to derive a classpath from. If not, do not start the tool repl:
    if (self.projectFileItem) {
        
        // Get the tool REPL going:

        [self populateJavaClassPathWithCompletion: ^(SEProjectDocument* document, NSError* error) {
            
            // Append bundle path to classPath:
            
            //NSString* additionalSourcesPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"Runtime-Support"] stringByAppendingPathComponent: self.currentLanguage];
            //self.javaClasspath = [self.javaClasspath stringByAppendingFormat: @":%@", additionalSourcesPath];
            
            if (! error) {
                [self startREPLServerWithCompletion: ^(SEREPLServer* server, NSError* error) {
                    // Connect to tool REPL:
                    if (error) {
                        NSLog(@"Error creating REPL server: %@", error);
                    } else {
                        
                        NSLog(@"Socket REPL ready. Connecting...");
                        [self.toolConnection openWithHostname: @"localhost"
                                                         port: server.port
                                                   completion: ^(SEREPLConnection* connection, NSError* error) {
                                                       if (! error) {
                                                           // Send test expression:
                                                           [connection sendExpression: @"(* 2 3)" timeout: 10.0 completion: ^(NSDictionary* resultDictionary) {
                                                               id exception = resultDictionary[SEREPLKeyException];
                                                               if (exception) {
                                                                   NSLog(@"Socket REPL got error: '%@' of class %@", exception, [exception class]);
                                                               } else {
                                                                   id result = resultDictionary[SEREPLKeyResult];
                                                                   NSLog(@"Socket REPL got result: '%@' of class %@", result, [result class]);
                                                               }
                                                           }];
                                                       } else {
                                                           NSLog(@"Error querying socket REPL: %@", error);
                                                       }
                                                   }];
                    }
                }];
            }
        }];
    }
}

+ (BOOL) autosavesInPlace {
    return YES;
}

//- (NSData*) dataOfType: (NSString*) typeName error: (NSError**) errorPtr {
//    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
//    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
////    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
////    @throw exception;
////    return nil;
//    
//    return [NSPropertyListSerialization dataWithPropertyList: projectSettings format: NSPropertyListXMLFormat_v1_0 options: 0 error: errorPtr];
//}
//
//- (BOOL) readFromData: (NSData*) projectData ofType: (NSString*) typeName error: (NSError**) errorPtr {
//    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
//    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
//    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
////    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
////    @throw exception;
//    
//    if (projectData) {
//        projectSettings = [NSPropertyListSerialization propertyListWithData: projectData options: NSPropertyListMutableContainers format: NULL error: errorPtr];
//    }
//    
//    return YES;
//}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
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

- (void) populateJavaClassPathWithCompletion: (void (^)(SEProjectDocument* document, NSError* error)) completed {

    if (self.javaClasspath.length) {
        if (completed) {
            completed(self, nil);
        }
        return;
    }
    
    NSTask* task = [[NSTask alloc] init];
    NSPipe* pipe = [NSPipe pipe];
    
    [task setLaunchPath: @"/usr/local/bin/lein"];
    [task setArguments: @[@"classpath"]];
    [task setStandardOutput: pipe];
    task.currentDirectoryPath = self.projectFolderItem.fileURL.path;
    
    NSFileHandle* file = [pipe fileHandleForReading];
    
//    [task setTerminationHandler: ^(NSTask* t) {
//        NSError* error = nil;
//        if (t.terminationStatus != 0) {
//            error = [[NSError alloc] initWithDomain: @"org.cocoanuts.s-explorer"
//                                               code: t.terminationStatus userInfo: nil];
//        }
//
//    }];
    
    [task launch];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        // Blocking read in background thread:
        NSData* data = [file readDataToEndOfFile];
        
        NSString* result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSError* error = nil;
            
            self.javaClasspath = [result stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if (! result.length) {
                NSLog(@"Error, got no classpath.");
                error = [NSError errorWithDomain: @"S-Explorer" code: 12 userInfo: nil]; // TODO: Populate error
            }
            
            if (completed) {
                completed(self, error);
            }
        });
    });
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

- (void) replServerDidStart: (SEREPLServer*) repl {
    if (repl.task.isRunning) {
        NSLog(@"replServerDidStart: %@", repl);
    }
}

- (IBAction) revealInSourceList: (id) sender {
    SESourceItem* currentSourceItem = self.currentSourceItem;
    
    if (currentSourceItem) {
        [self expandSourceListToItem: currentSourceItem];
        // Select itemAtPath in source list:
        NSUInteger itemRow = [self.sourceList rowForItem: currentSourceItem];
        
        if (itemRow != -1) {
            [self.sourceList selectRowIndexes: [NSIndexSet indexSetWithIndex: itemRow]
                         byExtendingSelection: NO];
            return;
        }
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
    
    //NSString* sourceContent = self.currentSourceItem.contents.string;
    
    //[self.toolConnection sendExpression: sourceContent timeout: 20.0 completion: ^(NSDictionary* evalResult) {
    //    NSLog(@"got %@", evalResult);
    //}];
    //[self saveDocument: sender];
    [self updateKeywords];
    [self saveSettings];
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

- (void) close {
    [self.toolConnection close];
    [self.replServer stop];
    [self.pathWatcher stopWatchingPaths];
    self.pathWatcher.delegate = nil;
    self.pathWatcher = nil;
    [self saveSettings];
    [super close];
}


- (void) canCloseDocumentWithDelegate: (id) delegate shouldCloseSelector: (SEL)shouldCloseSelector contextInfo: (void*) contextInfo {
    NSLog(@"closing sourceItems...");

    [self saveAllSourceItems: nil];
    
    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

@end

@implementation SEProjectDocument (SourceOutlineViewDataSource)
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
    [self.uiSettings mutableDictionaryForKey: @"expandedFolders"][[self relativePathForSourceItem: item]] = @YES;
    [self settingsNeedSave];
    return YES;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    [self.uiSettings[@"expandedFolders"] removeObjectForKey: [self relativePathForSourceItem: item]];
    [self settingsNeedSave];
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
