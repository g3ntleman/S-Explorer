//
//  SEDocumentController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 02.09.13.
//  Copyright (c) 2016 Cocoanuts.org. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SEProjectDocument.h"

@interface SEDocumentController : NSDocumentController

@end

@interface NSDocumentController (SEProjects)

- (SEProjectDocument*) projectForFileURL: (NSURL*) fileURL;

@end