//
//  BRProject
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "BRProject.h"
#import "NSAlert+OPBlocks.h"
#import "CSVM.h"
#import "BRSourceItem.h"
#import "NSDictionary+OPImmutablility.h"
#import "NoodleLineNumberView.h"

@implementation BRProject {
    CSVM* vm;
    NSMutableDictionary* uiSettings;
}

@synthesize tabbedSourceItems;
@synthesize sourceTab;
@synthesize sourceList;
@synthesize projectSettings;
//@synthesize uiSettings;

- (id) init {
    
    NSURL* sourceURL = [[NSBundle mainBundle] URLForResource: @"S-Explorer-support" withExtension: @"scm"];
    
    return [self initWithContentsOfURL: sourceURL ofType:@"scm" error: NULL];
    
}

- (id) initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    
    if (self = [super init]) {
        
        self.tabbedSourceItems = @{};
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDir]) {
            if (isDir) {
                projectSourceItem = [[BRSourceItem alloc] initWithFileURL: url];
            } else {
                projectSourceItem = [[BRSourceItem alloc] initWithFileURL: [url URLByDeletingLastPathComponent]];

                BRSourceItem* singleSourceItem = [projectSourceItem childWithName: [url lastPathComponent]];
                
                [self setSourceItem: singleSourceItem forIndex: 0];
            }
            return self;
        }
    }
    
    return nil;
}

/**
 * index should be 0..3 while item may be nil to indicate a removal.
 */
- (void) setSourceItem: (BRSourceItem*) item forIndex: (NSUInteger) index {
    
    NSParameterAssert([item isKindOfClass: [BRSourceItem class]]);
    if (item) {
        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryBySettingObject: item forKey: @(index)];
    } else {
        self.tabbedSourceItems = [self.tabbedSourceItems dictionaryByRemovingObjectForKey: @(index)];
    }
    
    [sourceTab setEnabled: item!=nil forSegment: index];
    [sourceTab setLabel: item.relativePath forSegment: index];
    
    if (index == sourceTab.selectedSegment) {
        [sourceList selectRowIndexes: [NSIndexSet indexSetWithIndex: [sourceList rowForItem: item]] byExtendingSelection: NO];
    }
    
}

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
    return @"BRProject";
}

- (BRSourceItem*) currentSourceItem {
    BRSourceItem* sourceItem = self.tabbedSourceItems[@(sourceTab.selectedSegment)];
    return sourceItem;
}

- (void) setCurrentSourceItem: (BRSourceItem*) sourceItem {
    
    NSTextStorage* textStorage = self.sourceTextView.textStorage;
    NSString* fileContent = sourceItem.content;
    if (! fileContent)
        fileContent = @"";
    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont fontWithName:@"Menlo-Bold" size: 12.0], NSFontAttributeName, nil, nil];
    NSAttributedString* attributedContent = [[NSAttributedString alloc] initWithString: fileContent attributes: attributes];
    textStorage.attributedString = attributedContent;
    
    // Colorize scheme files:
    if ([sourceItem.relativePath.pathExtension isEqualToString: @"scm"]) {
        [self colorizeCurrentFile: self];
    }
}

- (void) selectSourceTabWithIndex: (NSUInteger) tabIndex {
    BRSourceItem* sourceItem = self.tabbedSourceItems[@(tabIndex)];
    [self setCurrentSourceItem: sourceItem];
}

- (NSMutableDictionary*) projectSettings {
    
    if (! projectSettings) {
        NSString* projectFolderPath = self.projectSourceItem.absolutePath;
        NSString* projectFilePath = [projectFolderPath stringByAppendingPathComponent: [self.projectSourceItem.relativePath stringByAppendingPathExtension:@"sproj"]];
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
    NSString* uiFolderPath = self.projectSourceItem.absolutePath;
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

- (void) parser: (BRSchemeParser*) parser
     foundToken: (TokenOccurrence) tokenInstance
        atDepth: (NSInteger) depth
   elementCount: (NSUInteger) elementCount {
    
    NSTextStorage* textStorage = self.sourceTextView.textStorage;
    
    switch (tokenInstance.token) {
        case COMMENT: {
            NSDictionary* commentAttributes = @{NSForegroundColorAttributeName: [NSColor greenColor]};
            [textStorage addAttributes: commentAttributes range: tokenInstance.occurrence];
            break;
        }
        case ATOM: {
            if (elementCount == 0 && depth>=1) {
                NSColor* color = nil;
                NSString* word = [textStorage.string substringWithRange: tokenInstance.occurrence];
                
                
                if ([[BRSchemeParser keywords] containsObject: word]) {
                    color = [NSColor purpleColor];
                } else if ([[vm allSymbols] containsObject: word]) {
                    color = [NSColor blueColor];
                }
                
                if (color) {
                    NSDictionary* commentAttributes = @{NSForegroundColorAttributeName: color};
                    [textStorage addAttributes: commentAttributes range: tokenInstance.occurrence];
                }
            }
            break;
        }
        default:
            break;
    }
}


- (IBAction) colorizeCurrentFile: (id) sender {
    
    NSTextStorage* textStorage = self.sourceTextView.textStorage;
    
//    struct sexp_callbacks parserCallbacks;
//    parserCallbacks.handle_atom = &parser_handle_atom;
//    parserCallbacks.begin_list = &parser_begin_list;
//    parserCallbacks.end_list = &parser_end_list;
//    parserCallbacks.handle_error = &parser_handle_error;
//
//    // Parse parserCString calling the callbacks above:
//    int res = sexp_parse(parserCString, &parserCallbacks, (__bridge void*)self);

    BRSchemeParser* parser = [[BRSchemeParser alloc] initWithString: textStorage.string];
    parser.delegate = self;
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    [parser parse];
    NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
    NSLog(@"Parsing & Highlighting took %lf seconds.", endTime-startTime);

}

- (IBAction) sourceTableAction: (id) sender {
    NSLog(@"sourceTableAction.");
    BRSourceItem* selectedSourceItem = [self.sourceList itemAtRow: self.sourceList.selectedRow];
    [self setCurrentSourceItem: selectedSourceItem];
}

- (IBAction) selectSourceTab: (id) sender {
    
    NSLog(@"selected tab #%lu", sourceTab.selectedSegment);
    BRSourceItem* sourceItem = self.tabbedSourceItems[@(sourceTab.selectedSegment)];
    
    [self setCurrentSourceItem: sourceItem];
}

- (IBAction) saveCurrentSourceItem: (id) sender {
    
    BRSourceItem* currentSource = self.currentSourceItem;
    
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
    
    BRSourceItem* currentSource = self.currentSourceItem;
    if (currentSource.contentHasChanged) {
        [currentSource revertContent];
        [self setCurrentSourceItem: currentSource];
    }
}


- (IBAction) run: (id) sender {
    
    NSString* res = [vm evaluateToStringFromString: @"(repl)"];
    
    NSLog(@"repl result = %@", res);
    
}


- (void) windowControllerDidLoadNib: (NSWindowController*) aController {
    
    [super windowControllerDidLoadNib: aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    [self.sourceList setDraggingSourceOperationMask: NSDragOperationLink forLocal: NO];

    
    NSScrollView* scrollView = self.sourceTextView.enclosingScrollView;
    NoodleLineNumberView* lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView: scrollView];
    [scrollView setVerticalRulerView: lineNumberView];
    [scrollView setHasHorizontalRuler: NO];
    [scrollView setHasVerticalRuler: YES];
    [scrollView setRulersVisible: YES];

    
    
    NSError* error = nil;
//    [self.replController runCommand: @"/usr/local/bin/csi"
//                      withArguments: @[@"-n"]
//                              error: &error];
//    
//    if (error) {
//        [[NSAlert alertWithError: error] runWithCompletion:^(NSInteger buttonIndex) {
//            [self performSelector: @selector(close) withObject: nil afterDelay: 0.1];
//        }];
//    }
    
    vm = [[CSVM alloc] init];
    
//    NSString* input1 = @"(import (scheme base))";
//    NSString* output1 = [vm evaluateToStringFromString: input1];
    
    [vm evaluateToStringFromString: @"(import (chibi repl))"];

    
    [vm loadSchemeSource: @"S-Explorer-support" error: &error];

    //NSString* input2 = @"(sort (list 5 4 2 3 1 6) <)";
    //NSString* output2 = [vm evaluateString: input2];

    //NSLog(@"All symbols: %@\n%@", input3, allSymbolStrings);
    NSLog(@"All VM symbols: %@", vm.allSymbols);
    
    [vm locationOfProcedureNamed: @"map"];
    
    [self setSourceItem: tabbedSourceItems[@(sourceTab.selectedSegment)] forIndex: sourceTab.selectedSegment];
    [self selectSourceTabWithIndex: 0];
    
    for (NSString* path in self.uiSettings[@"expandedFolders"]) {
        BRSourceItem* item = [self.projectSourceItem childWithPath: path];
        [self.sourceList expandItem: item];
    }
    
}

+ (BOOL)autosavesInPlace {
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

@synthesize projectSourceItem;

- (BRSourceItem*) projectSourceItem {
    if (! projectSourceItem) {
        projectSourceItem = [[BRSourceItem alloc] initWithFileURL: [self fileURL]];
    }
    return projectSourceItem;
}

@end

@implementation BRProject (SourceOutlineViewDataSource)
// Data Source methods

- (NSInteger) outlineView:(NSOutlineView*) outlineView numberOfChildrenOfItem: (id) item {
    if (item == nil) {
        item = self.projectSourceItem;
    }
    NSInteger noc = [[item children] count];
    return noc;
}


- (BOOL) outlineView: (NSOutlineView*) outlineView isItemExpandable: (id) item {
    if (item == nil) {
        item = self.projectSourceItem;
    }
    return  [item children] != nil;
}


- (id) outlineView: (NSOutlineView*) outlineView child:(NSInteger)index ofItem:(id)item {
    
    if (item == nil) {
        item = self.projectSourceItem;
    }
        
    return [item children][index];
}


- (id) outlineView: (NSOutlineView*) outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    
    //NSLog(@"Finding objectValue for %@", item);
    if (item == nil) {
        item = self.projectSourceItem;
    }
    
    return [item relativePath];
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    BRSourceItem* sourceItem = item;
    NSString* path = sourceItem.longRelativePath;
    self.uiSettings[@"expandedFolders"][path] = @YES;
    [self uiSettingsNeedSave];
    return YES;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    BRSourceItem* sourceItem = item;
    NSString* path = sourceItem.longRelativePath;
    [self.uiSettings[@"expandedFolders"] removeObjectForKey: path];
    [self uiSettingsNeedSave];
    return YES;
}

- (IBAction) revealInFinder: (id) sender {
    BRSourceItem* selectedItem  = [sourceList itemAtRow: sourceList.selectedRowIndexes.firstIndex];
    NSString* selectedItemPath = selectedItem.absolutePath;
    [[NSWorkspace sharedWorkspace] selectFile: selectedItemPath inFileViewerRootedAtPath: nil];
}



- (BOOL) outlineView: (NSOutlineView*) outlineView writeItems: (NSArray*) items toPasteboard:(NSPasteboard *)pboard {
    // Set the pasteboard for File promises only
    [pboard declareTypes: @[NSURLPboardType] owner:self];
    
    // The pasteboard must know the type of files being promised:
    
    NSMutableSet* urlStrings = [NSMutableSet set];
    for (BRSourceItem* item in items) {
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
    return (BRSourceItem*)item;
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
