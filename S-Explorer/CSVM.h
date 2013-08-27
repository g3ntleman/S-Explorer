//
//  OPChibiVM.h
//  S-Explorer
//
//  Created by Dirk Theisen on 28.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <chibi/eval.h>


//@interface CSSExpression : NSObject
//
//@end

@interface CSVM : NSObject {
    sexp ctx;
}

@property (readonly) NSArray* allSymbols; // sorted

- (id) evaluateToPropertyListFromString: (NSString*) expressionString error: (NSError**) errorPtr;
- (NSString*) evaluateToStringFromString: (NSString*) expressionString;

- (BOOL) loadSchemeSource: (NSString*) filenameOrPath error: (NSError**) errorPtr;

- (NSArray*) locationOfProcedureNamed: (NSString*) procedureName;

- (void) setStandardFileHandlesForIn: (NSFileHandle*) inHandle
                                 out: (NSFileHandle*) outHandle
                               error: (NSFileHandle*) errHandle;

@end
