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

@implementation BRProject {
    CSVM* vm;
}

@synthesize tabbedSourceItems;

- (id) init {
    
    NSURL* sourceURL = [[NSBundle mainBundle] URLForResource: @"bracket-support" withExtension: @"scm"];
    
    return [self initWithContentsOfURL: sourceURL ofType:@"scm" error: NULL];
    
}

- (id) initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    
    if (self = [super init]) {
        
        tabbedSourceItems = @[];
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDir]) {
            if (isDir) {
                projectSourceItem = [[BRSourceItem alloc] initWithFileURL: url];
            } else {
                projectSourceItem = [[BRSourceItem alloc] initWithFileURL: [url URLByDeletingLastPathComponent]];

                BRSourceItem* singleSourceItem = [projectSourceItem childWithName: [url lastPathComponent]];
                
                tabbedSourceItems = @[singleSourceItem];
            }
            return self;
        }
    }
    
    return nil;
}

- (NSString *)windowNibName {
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"BRProject";
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


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
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
    
    //[vm evaluateToStringFromString: @"(import (chibi ast))"];

    
    [vm loadSchemeSource: @"bracket-support" error: &error];

    //NSString* input2 = @"(sort (list 5 4 2 3 1 6) <)";
    //NSString* output2 = [vm evaluateString: input2];

    //NSLog(@"All symbols: %@\n%@", input3, allSymbolStrings);
    NSLog(@"All VM symbols: %@", vm.allSymbols);
    
    NSTextStorage* textStorage = self.sourceTextView.textStorage;
    
    NSString* sourcePath = [[NSBundle mainBundle] pathForResource:@"bracket-support" ofType:@"scm"];
    NSString* fileContent = [NSString stringWithContentsOfFile: sourcePath
                                                      encoding: NSUTF8StringEncoding
                                                         error: NULL];
    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont fontWithName:@"Menlo-Bold" size: 12.0], NSFontAttributeName, nil, nil];
    NSAttributedString* attributedContent = [[NSAttributedString alloc] initWithString: fileContent attributes: attributes];

                                            
    textStorage.attributedString = attributedContent;
    
    [self colorizeCurrentFile: self];
    
    
    self.fileURL = [[NSBundle mainBundle] resourceURL];
    
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
    
    NSLog(@"Finding objectValue for %@", item);
    if (item == nil) {
        item = self.projectSourceItem;
    }
    
    return [item relativePath];
}

@end
