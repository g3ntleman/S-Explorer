//
//  BRDocument.m
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "BRDocument.h"
#import "NSAlert+OPBlocks.h"
#import "CSVM.h"

@implementation BRDocument

- (id)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"BRDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    NSError* error = nil;
    [self.replController runCommand: @"/usr/local/bin/csi"
                      withArguments: @[@"-n"]
                              error: &error];
    
    if (error) {
        [[NSAlert alertWithError: error] runWithCompletion:^(NSInteger buttonIndex) {
            [self performSelector: @selector(close) withObject: nil afterDelay: 0.1];
        }];
    }
    
    CSVM* vm = [[CSVM alloc] init];
    
    NSString* input1 = @"(import (scheme base))";
    NSString* output1 = [vm evaluateToStringFromString: input1];
    
    [vm loadSchemeSource: @"bracket-support"];

    //NSString* input2 = @"(sort (list 5 4 2 3 1 6) <)";
    //NSString* output2 = [vm evaluateString: input2];
    NSString* input3 = @"(all-exports (interaction-environment))";
    NSMutableArray* allSymbolStrings = [vm evaluateToPropertyListFromString: input3];

    [allSymbolStrings sortUsingSelector:@selector(compare:)];
    
    
    NSLog(@"\n> %@\n%@", input3, allSymbolStrings);
    
}

+ (BOOL)autosavesInPlace {
    return YES;
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

@end
