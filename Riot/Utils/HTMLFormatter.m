// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "HTMLFormatter.h"
#import "GeneratedInterface-Swift.h"

@implementation HTMLFormatter

- (NSAttributedString *)formatHTML:(NSString *)htmlString withAllowedTags:(NSArray<NSString *> *)allowedTags fontSize:(CGFloat)fontSize
{
    // TODO: This method should be more general purpose and usable from MXKEventFormatter and GroupHomeViewController
    // FIXME: The implementation is currently in Objective-C as there is a crash in the callback when implemented in Swift
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    // Do some sanitisation before finalizing the string
    DTHTMLAttributedStringBuilderWillFlushCallback sanitizeCallback = ^(DTHTMLElement *element) {
        [element sanitizeWith:allowedTags bodyFont:font imageHandler:nil];
    };

    NSDictionary *options = @{
                              DTUseiOS6Attributes: @(YES),              // Enable it to be able to display the attributed string in a UITextView
                              DTDefaultFontFamily: font.familyName,
                              DTDefaultFontName: font.fontName,
                              DTDefaultFontSize: @(font.pointSize),
                              DTDefaultLinkDecoration: @(NO),
                              DTWillFlushBlockCallBack: sanitizeCallback
                              };

    // Do not use the default HTML renderer of NSAttributedString because this method
    // runs on the UI thread which we want to avoid because renderHTMLString is called
    // most of the time from a background thread.
    // Use DTCoreText HTML renderer instead.
    // Using DTCoreText, which renders static string, helps to avoid code injection attacks
    // that could happen with the default HTML renderer of NSAttributedString which is a
    // webview.
    NSAttributedString *string = [[NSAttributedString alloc] initWithHTMLData:[htmlString dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:NULL];
        
    // Apply additional treatments
    string = [MXKTools removeDTCoreTextArtifacts:string];
    
    if (!string) {
        return [[NSAttributedString alloc] initWithString:htmlString];
    }
    
    return string;
}

@end
