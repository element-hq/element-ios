/*
Copyright 2020 New Vector Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#import "EventFormatter+DTCoreTextFix.h"

@import UIKit;
@import CoreText;
@import ObjectiveC;

#pragma mark - UIFont DTCoreText fix

@interface UIFont (vc_DTCoreTextFix)

+ (UIFont *)vc_fixedFontWithCTFont:(CTFontRef)ctFont;

@end

@implementation UIFont (vc_DTCoreTextFix)

+ (UIFont *)vc_fixedFontWithCTFont:(CTFontRef)ctFont {
    NSString *fontName = (__bridge_transfer NSString *)CTFontCopyName(ctFont, kCTFontPostScriptNameKey);

    CGFloat fontSize = CTFontGetSize(ctFont);
    UIFont *font = [UIFont fontWithName:fontName size:fontSize];

    // On iOS 13+ "TimesNewRomanPSMT" will be used instead of "SFUI"
    // In case of "Times New Roman" fallback, use system font and reuse UIFontDescriptorSymbolicTraits.
    if ([font.familyName.lowercaseString containsString:@"times"])
    {
        UIFontDescriptorSymbolicTraits symbolicTraits = (UIFontDescriptorSymbolicTraits)CTFontGetSymbolicTraits(ctFont);
        
        UIFontDescriptor *systemFontDescriptor = [UIFont systemFontOfSize:fontSize].fontDescriptor;
        
        UIFontDescriptor *finalFontDescriptor = [systemFontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
        font = [UIFont fontWithDescriptor:finalFontDescriptor size:fontSize];
    }

    return font;
}

@end

#pragma mark - Implementation

@implementation EventFormatter(DTCoreTextFix)

// DTCoreText iOS 13 fix. See issue and comment here: https://github.com/Cocoanetics/DTCoreText/issues/1168#issuecomment-583541514
+ (void)fixDTCoreTextFont
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        Class originalClass = object_getClass([UIFont class]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL originalSelector = @selector(fontWithCTFont:); // DTCoreText method we're overriding
        SEL ourSelector = @selector(vc_fixedFontWithCTFont:); // Use custom implementation
#pragma clang diagnostic pop
        
        Method originalMethod = class_getClassMethod(originalClass, originalSelector);
        Method swizzledMethod = class_getClassMethod(originalClass, ourSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

@end
