//
//  OPChibiVM.h
//  Bracket
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

- (id) evaluateToPropertyListFromString: (NSString*) expressionString;
- (NSString*) evaluateToStringFromString: (NSString*) expressionString;

- (BOOL) loadSchemeSource: (NSString*) filenameOrPath;

@end
