/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "NSBundle+MatrixKit.h"
#import "NSBundle+MXKLanguage.h"
#import "MXKViewController.h"

@implementation NSBundle (MatrixKit)

static NSString *customLocalizedStringTableName = nil;

+ (NSBundle*)mxk_assetsBundle
{
    // Get the bundle within MatrixKit
    NSBundle *bundle = [NSBundle mxk_bundleForClass:[MXKViewController class]];
    NSURL *assetsBundleURL = [bundle URLForResource:@"MatrixKitAssets" withExtension:@"bundle"];

    return [NSBundle bundleWithURL:assetsBundleURL];
}

+ (NSBundle*)mxk_languageBundle
{
    NSString *language = [NSBundle mxk_language];
    NSBundle *bundle = [NSBundle mxk_assetsBundle];

    // If there is a runtime language (different from the legacy language chose by the OS),
    // return the sub bundle for this language
    if (language)
    {
        bundle =  [NSBundle bundleWithPath:[bundle pathForResource:[NSBundle mxk_language] ofType:@"lproj"]];
    }

    return bundle;
}

+ (NSBundle*)mxk_fallbackLanguageBundle
{
    NSString *fallbackLanguage = [NSBundle mxk_fallbackLanguage];
    NSBundle *bundle = [NSBundle mxk_assetsBundle];

    // Return the sub bundle of the fallback language if any
    if (fallbackLanguage)
    {
        bundle =  [NSBundle bundleWithPath:[bundle pathForResource:fallbackLanguage ofType:@"lproj"]];
    }

    return bundle;
}

// use a cache to avoid loading images from file system.
// It often triggers an UI lag.
static MXLRUCache *imagesResourceCache = nil;

+ (UIImage *)mxk_imageFromMXKAssetsBundleWithName:(NSString *)name
{
    // use a cache to avoid loading the image at each call
    if (!imagesResourceCache)
    {
        imagesResourceCache = [[MXLRUCache alloc] initWithCapacity:20];
    }
    
    NSString *imagePath = [[NSBundle mxk_assetsBundle] pathForResource:name ofType:@"png" inDirectory:@"Images"];
    UIImage* image = (UIImage*)[imagesResourceCache get:imagePath];
    
    // the image does not exist
    if (!image)
    {
        // retrieve it
        image = [UIImage imageWithContentsOfFile:imagePath];
        // and store it in the cache.
        [imagesResourceCache put:imagePath object:image];
    }
    
    return image;
}

+ (NSURL*)mxk_audioURLFromMXKAssetsBundleWithName:(NSString *)name
{
    return [NSURL fileURLWithPath:[[NSBundle mxk_assetsBundle] pathForResource:name ofType:@"mp3" inDirectory:@"Sounds"]];
}

+ (void)mxk_customizeLocalizedStringTableName:(NSString*)tableName
{
    customLocalizedStringTableName = tableName;
}

+ (NSString *)mxk_localizedStringForKey:(NSString *)key
{
    NSString *localizedString;
    
    // Check first customized table
    // Use "_", a string that does not worth to be translated, as default value to mark
    // a key that does not have a value in the customized table.
    if (customLocalizedStringTableName)
    {
        localizedString = NSLocalizedStringWithDefaultValue(key, customLocalizedStringTableName, [NSBundle mainBundle], @"_", nil);
    }

    if (!localizedString || (localizedString.length == 1 && [localizedString isEqualToString:@"_"]))
    {
        // Check if we need to manage a fallback language
        // as we do in NSBundle+MXKLanguage
        NSString *language = [NSBundle mxk_language];
        NSString *fallbackLanguage = [NSBundle mxk_fallbackLanguage];

        BOOL manageFallbackLanguage = fallbackLanguage && ![fallbackLanguage isEqualToString:language];

        localizedString = NSLocalizedStringWithDefaultValue(key, @"MatrixKit",
                                                            [NSBundle mxk_languageBundle],
                                                            manageFallbackLanguage ? @"_" : nil,
                                                            nil);

        if (manageFallbackLanguage
            && (!localizedString || (localizedString.length == 1 && [localizedString isEqualToString:@"_"])))
        {
            // The translation is not available, use the fallback language
            localizedString = NSLocalizedStringFromTableInBundle(key, @"MatrixKit",
                                                                 [NSBundle mxk_fallbackLanguageBundle],
                                                                 nil);
        }
    }
    
    return localizedString;
}

+ (NSBundle *)mxk_bundleForClass:(Class)aClass
{
    NSBundle *bundle = [NSBundle bundleForClass:aClass];
    if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"])
    {
        // For App extensions, peel off two levels
        bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    }
    return bundle;
}

@end
