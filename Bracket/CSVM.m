//
//  OPChibiVM.m
//  Bracket
//
//  Created by Dirk Theisen on 28.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import "CSVM.h"
#include <chibi/sexp.h>


@implementation CSVM

@synthesize allSymbols;

- (id) init {
    if (self = [super init]) {
        ctx = sexp_make_eval_context(NULL, NULL, NULL, 0, 0);
        sexp_load_standard_env(ctx, NULL, SEXP_SEVEN);
        sexp_load_standard_ports(ctx, NULL, stdin, stdout, stderr, 0);
    }
    return self;
}

#define NUMBUF_LEN 32


- (id) propertyListFromSExpression: (sexp) obj {
 
    unsigned long len;
//    unsigned long c;
    long i=0;
#if SEXP_USE_FLONUMS
    double f;
#endif
    sexp x, *elts;
    char *str=NULL, numbuf[NUMBUF_LEN];
    
    if (! obj) {
        return nil; // shouldn't happen
    } else if (sexp_pointerp(obj)) {
        switch (sexp_pointer_tag(obj)) {
            case SEXP_PAIR: {
                // Turn lists into Arrays:
                
                NSMutableArray* array = [[NSMutableArray alloc] init];
                id element; // = [self propertyListFromSExpression: sexp_car(obj)];
//                if (element) [array addObject: element];
                for (x=obj; sexp_pairp(x); x=sexp_cdr(x)) {
                    element = [self propertyListFromSExpression: sexp_car(x)];
                    if (element) [array addObject: element];
                }
                if (! sexp_nullp(x)) {
                    element = [self propertyListFromSExpression: sexp_car(x)];
                    if (element) [array addObject: element];
                }
                return array;
            }
            case SEXP_VECTOR: {
                len = sexp_vector_length(obj);
                elts = sexp_vector_data(obj);
                if (len == 0) {
                    return [[NSArray alloc] init];
                } else {
                    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity: len];
                    for (i=0; i<len; i++) {
                        id element = [self propertyListFromSExpression: elts[i]];
                        if (element) [array addObject: element];
                    }
                    return array;
                }
            }
#if SEXP_USE_FLONUMS
#if ! SEXP_USE_IMMEDIATE_FLONUMS
            case SEXP_FLONUM: {
                f = sexp_flonum_value(obj);
#if SEXP_USE_INFINITIES
                if (isnan(f)) {
                    return (id)kCFNumberNaN;
                }
                if (isinf(f)) {
                    return f < 0 ? (id)kCFNumberNegativeInfinity : (id)kCFNumberPositiveInfinity;
                } else
#endif
                {
                    return [NSNumber numberWithDouble:f];
                }
            }
#endif
#endif
                //            case SEXP_PROCEDURE:
                //                sexp_write_string(ctx, "#<procedure ", out);
                //                x = sexp_bytecode_name(sexp_procedure_code(obj));
                //                sexp_write_one(ctx, sexp_synclop(x) ? sexp_synclo_expr(x): x, out);
                //#if SEXP_USE_DEBUG_VM
                //                if (sexp_procedure_source(obj)) {
                //                    sexp_write_string(ctx, " ", out);
                //                    sexp_write(ctx, sexp_procedure_source(obj), out);
                //                }
                //#endif
                //                sexp_write_string(ctx, ">", out);
                //                break;
                //            case SEXP_TYPE:
                //                sexp_write_string(ctx, "#<type ", out);
                //                sexp_write(ctx, sexp_type_name(obj), out);
                //                sexp_write_string(ctx, ">", out);
                //                break;
            case SEXP_STRING: {
                
                NSUInteger offset = sexp_string_offset(obj);
                NSString* string = [[NSString alloc] initWithBytes: sexp_string_data(obj)+offset
                                                            length: sexp_string_length(obj)-offset
                                                          encoding: NSUTF8StringEncoding];
                return string;
            };
            case SEXP_SYMBOL: {
                str = sexp_lsymbol_data(obj);
                NSString* symbolString = [[NSString alloc] initWithBytes: str
                                                                  length: sexp_lsymbol_length(obj)
                                                                encoding: NSUTF8StringEncoding];
                
                //                c = sexp_lsymbol_length(obj) > 0 ? EOF : '|';
                //                for (i=sexp_lsymbol_length(obj)-1; i>=0; i--)
                //                    if (str[i] <= ' ' || str[i] == '\\' || sexp_is_separator(str[i])) c = '|';
                //                if (c!=EOF) sexp_write_char(ctx, c, out);
                //                for (i=sexp_lsymbol_length(obj); i>0; str++, i--) {
                //                    if (str[0] == '\\') sexp_write_char(ctx, '\\', out);
                //                    sexp_write_char(ctx, str[0], out);
                //                }
                //                if (c!=EOF) sexp_write_char(ctx, c, out);
                // NSLog(@"Found Symbol '%@'", symbolString);
                
                return symbolString;
            };
            case SEXP_EXCEPTION: {
                
                sexp_gc_var5(message, kind, irritants, procedure, source);
                sexp_gc_preserve5(ctx, message, kind, irritants, procedure, source);

                //sexp_print_exception(ctx, obj, outputPort);
                //NSString* exceptionString = [self stringFromSExpression: sexp_print_exception_op obj];
                
                message = sexp_exception_message(obj);
                
                kind = sexp_exception_kind(obj);
                irritants = sexp_exception_irritants(obj);
                procedure = sexp_exception_procedure(obj);
                source = sexp_exception_source(obj);
                
                sexp_gc_release5(ctx);
                
                NSString* messageString = [self propertyListFromSExpression: message];
                NSString* procedureString = [self propertyListFromSExpression: procedure];
                NSString* kindString = [self propertyListFromSExpression: kind];
                NSArray* irritantsArray = [self propertyListFromSExpression: irritants];
                NSString* sourceString = [self propertyListFromSExpression: source];
                NSLog(@"Scheme Exception '%@' (%@)", messageString, [irritantsArray componentsJoinedByString:@","]);
                return [NSError errorWithDomain:@"BKSchemeDomain" code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey: messageString}];
            }
                
        }
    }
#if SEXP_USE_HUFF_SYMS
    else if (sexp_isymbolp(obj)) {
        sexp_gc_var1(str);
        sexp_gc_preserve1(ctx, str);
        str = sexp_symbol_to_string(ctx, obj);
        NSString* result = [self propertyListFromSExpression: str];
        sexp_gc_release1(ctx);
        return result;
    }
#endif
       else {
           // Simple inline expressions:
           switch ((sexp_uint_t) obj) {
            case (sexp_uint_t) SEXP_NULL:
                return [NSNull null];
            case (sexp_uint_t) SEXP_TRUE:
                return [NSNumber numberWithBool: YES];
            case (sexp_uint_t) SEXP_FALSE:
                return [NSNumber numberWithBool: NO];
            case (sexp_uint_t) SEXP_VOID:
                return nil;
            case (sexp_uint_t) SEXP_EOF:
            case (sexp_uint_t) SEXP_UNDEF:
            default: {
                NSLog(@"invalid immediate sexp.");
            }
                
        }
    }
    return nil;
}
 


    
//    sexp_tag_t tag = expression->tag;
//    switch (tag) {
//        case SEXP_STRING: {
//            NSUInteger offset = sexp_string_offset(expression);
//            NSString* resultString = [[NSString alloc] initWithBytes: sexp_string_data(expression)+offset
//                                                              length: sexp_string_length(expression)-offset
//                                                            encoding: NSUTF8StringEncoding];
//            return resultString;
//        }
//        case SEXP_OBJECT: {
//            
//            
//            break;
//        }
//        default:
//            break;
//    }
    
- (NSString*) stringFromSExpression: (sexp) obj {

    if (! sexp_stringp(obj)) {
        sexp_gc_var1(str);
        sexp_gc_preserve1(ctx, str);
        str = sexp_write_to_string(ctx, obj);
        NSString* result = [self propertyListFromSExpression: str];
        sexp_gc_release1(ctx);
        return result;
    }

    return [self propertyListFromSExpression: obj];
}

- (BOOL) loadSchemeSource: (NSString*) filenameOrPath error: (NSError**) errorPtr {
    
    NSString* path = filenameOrPath;
    if (! [[NSFileManager defaultManager] fileExistsAtPath: path]) {
        path = [[NSBundle mainBundle] pathForResource: filenameOrPath ofType: @"scm"];
    }
    if (! path.length) {
        return NO;
    }
    
    BOOL result = YES;
    
    sexp_gc_var2(pathExpression, res);
    sexp_gc_preserve2(ctx, pathExpression, res);

    pathExpression = sexp_c_string(ctx, [path UTF8String], -1);
    
    res = sexp_load(ctx, pathExpression, NULL);
    
    id resultPlist = [self propertyListFromSExpression: res];
    
    if (sexp_exceptionp(res) ){
        sexp_print_exception(ctx, res, sexp_current_error_port(ctx));
        if (errorPtr) {
            *errorPtr = resultPlist;
        }
        result = NO;
    }
    sexp_gc_release2(ctx);
    
    allSymbols = nil; // clear cache
    
    return result;
}

- (id) evaluateToPropertyListFromString: (NSString*) expressionString error: (NSError**) errorPtr {
    
    const char* cString = [expressionString cStringUsingEncoding:NSUTF8StringEncoding];
    
    sexp_gc_var1(resultExpression);
    sexp_gc_preserve1(ctx, resultExpression);
    
    resultExpression = sexp_eval_string(ctx, cString, -1, NULL);
    
    id result = [self propertyListFromSExpression: resultExpression];

    if ( sexp_exceptionp(resultExpression) ){
        sexp_print_exception(ctx, resultExpression, sexp_current_error_port(ctx));
        
        if (errorPtr) {
            *errorPtr = result;
        }
        
        result = nil;
    }
    
    sexp_release_object(ctx, resultExpression);
    
    return result;
}

//static sexp check_exception (sexp ctx, sexp res) {
//    sexp err;
//    if (res && sexp_exceptionp(res)) {
//        err = sexp_current_error_port(ctx);
//        if (! sexp_oportp(err))
//            err = sexp_make_output_port(ctx, stderr, SEXP_FALSE);
//        sexp_print_exception(ctx, res, err);
//        sexp_stack_trace(ctx, err);
//        exit_failure();
//    }
//    return res;
//}


- (NSString*) evaluateToStringFromString: (NSString*) expressionString {
    
    const char* cString = [expressionString cStringUsingEncoding:NSUTF8StringEncoding];
    
    sexp_gc_var1(resultExpression);
    sexp_gc_preserve1(ctx, resultExpression);

    resultExpression = sexp_eval_string(ctx, cString, -1, NULL);
    
    if ( sexp_exceptionp(resultExpression) ){
        sexp_print_exception(ctx, resultExpression, sexp_current_error_port(ctx));
    }
    
    NSString*  result = [self stringFromSExpression: resultExpression];
    
    sexp_release_object(ctx, resultExpression);
    
    return result;
}

- (NSArray*) allSymbols {
    if (!allSymbols) {
        NSString* symbolQuery = @"(all-exports (interaction-environment))";
        NSMutableArray* allSymbolStrings = [self evaluateToPropertyListFromString: symbolQuery error: nil];
        [allSymbolStrings sortUsingSelector:@selector(compare:)];
        allSymbols = allSymbolStrings;
    }
    return allSymbols;
}

- (void) dealloc {
    sexp_destroy_context(ctx);
}


@end
