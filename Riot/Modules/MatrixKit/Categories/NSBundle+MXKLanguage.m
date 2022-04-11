/*
 Copyright 2017 Vector Creations Ltd

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

#import "NSBundle+MXKLanguage.h"
#import "GeneratedInterface-Swift.h"

#import <objc/runtime.h>

static const char _bundle = 0;
static const char _fallbackBundle = 0;
static const char _language = 0;
static const char _fallbackLanguage = 0;

@interface MXKLanguageBundle : NSBundle
@end

@implementation MXKLanguageBundle

- (NSString*)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    NSBundle* bundle = objc_getAssociatedObject(self, &_bundle);

    // Check if the translation is available in the selected or default language.
    // Use "_", a string that does not worth to be translated, as default value to mark
    // a key that does not have a translation.
    NSString *localizedString = bundle ? [bundle localizedStringForKey:key value:@"_" table:tableName] : [super localizedStringForKey:key value:@"_" table:tableName];

    if (!localizedString || (localizedString.length == 1 && [localizedString isEqualToString:@"_"]))
    {
        // Use the string in the fallback language
        NSBundle *fallbackBundle = objc_getAssociatedObject(self, &_fallbackBundle);
        localizedString = [fallbackBundle localizedStringForKey:key value:value table:tableName];
    }

    return localizedString;
}
@end

@implementation NSBundle (MXKLanguage)

+ (void)mxk_setLanguage:(NSString *)language
{
    [self setupMXKLanguageBundle];

    // [NSBundle localizedStringForKey] calls will be redirected to the bundle corresponding
    // to "language". `lprojBundleFor` loads this from the main app bundle as we might be running in an extension.
    objc_setAssociatedObject(NSBundle.app,
                             &_bundle, language ? [NSBundle lprojBundleFor:language] : nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    objc_setAssociatedObject(NSBundle.app,
                             &_language, language,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSString *)mxk_language
{
    return objc_getAssociatedObject(NSBundle.app, &_language);
}

+ (void)mxk_setFallbackLanguage:(NSString *)language
{
    [self setupMXKLanguageBundle];

    objc_setAssociatedObject(NSBundle.app,
                             &_fallbackBundle, language ? [NSBundle lprojBundleFor:language] : nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    objc_setAssociatedObject(NSBundle.app,
                             &_fallbackLanguage, language,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSString *)mxk_fallbackLanguage
{
    return objc_getAssociatedObject(NSBundle.app, &_fallbackLanguage);
}

#pragma mark - Private methods

+ (void)setupMXKLanguageBundle
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        // Use MXKLanguageBundle as the [NSBundle mainBundle] class
        object_setClass(NSBundle.app, MXKLanguageBundle.class);
    });
}

@end
