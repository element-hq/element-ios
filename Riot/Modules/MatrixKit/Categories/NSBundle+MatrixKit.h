/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

/**
 Define a `NSBundle` category at MatrixKit level to retrieve images and sounds from MatrixKit Assets bundle.
 */
@interface NSBundle (MatrixKit)

/**
 Retrieve an image from MatrixKit Assets bundle.
 
 @param name image file name without extension.
 @return a UIImage instance (nil if the file does not exist).
 */
+ (UIImage *)mxk_imageFromMXKAssetsBundleWithName:(NSString *)name;

/**
 Retrieve an audio file url from MatrixKit Assets bundle.
 
 @param name audio file name without extension.
 @return a NSURL instance.
 */
+ (NSURL *)mxk_audioURLFromMXKAssetsBundleWithName:(NSString *)name;

/**
 An AppExtension-compatible wrapper for bundleForClass.
 */
+ (NSBundle *)mxk_bundleForClass:(Class)aClass;

@end
