/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "NSBundle+MatrixKit.h"
#import "NSBundle+MXKLanguage.h"
#import "MXKAppSettings.h"

@implementation NSBundle (MatrixKit)

+ (NSBundle*)mxk_assetsBundle
{
    // Get the bundle within MatrixKit
    NSBundle *bundle = [NSBundle mxk_bundleForClass:[MXKAppSettings class]];
    NSURL *assetsBundleURL = [bundle URLForResource:@"MatrixKitAssets" withExtension:@"bundle"];

    return [NSBundle bundleWithURL:assetsBundleURL];
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
