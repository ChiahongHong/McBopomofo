//
// PreferencesWindowController.m
//
// Copyright (c) 2011 The McBopomofo Project.
//
// Contributors:
//     Mengjuei Hsieh (@mjhsieh)
//     Weizhong Yang (@zonble)
//
// Based on the Syrup Project and the Formosana Library
// by Lukhnos Liu (@lukhnos).
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
#import "PreferencesWindowController.h"

@implementation PreferencesWindowController
@synthesize fontSizePopUpButton = _fontSizePopUpButton;

- (void)awakeFromNib
{
    // this is a way to find if we're on OS X 10.7
//    if (![[NSApplication sharedApplication] respondsToSelector:@selector(disableRelaunchOnLogin)]) {
//        return;
//    }
    
    NSMenu *menu = [_fontSizePopUpButton menu];
    NSArray *menuItems = [menu itemArray];
    
    for (NSMenuItem *item in menuItems) {
        NSUInteger tag = [item tag];
        
        if (tag != 14 && tag != 24) {
            [menu removeItem:item];
        }
    }
}
@end