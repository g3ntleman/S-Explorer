//
//  SESourceTextViewController.h
//  S-Explorer
//
//  Created by Dirk Theisen on 07.01.14.
//  Copyright (c) 2014 Cocoanuts. All rights reserved.
//

#import <AppKit/AppKit.h>

@class SESourceEditorTextView;

@interface SESourceTextViewController : NSController <NSTextDelegate, NSTextViewDelegate> {
}

@property(nonatomic, strong) IBOutlet SESourceEditorTextView* textView;

- (IBAction) expandSelection: (id) sender;

@end
