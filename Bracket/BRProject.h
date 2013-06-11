//
//  BRDocument.h
//  Bracket
//
//  Created by Dirk Theisen on 09.05.13.
//  Copyright (c) 2013 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BRREPLController.h"
#import "BRSchemeParser.h"

@interface BRProject : NSDocument <BRSchemeParserDelegate>

@property (strong) IBOutlet BRREPLController* replController;
@property (strong) IBOutlet NSTextView* sourceTextView;


@end
