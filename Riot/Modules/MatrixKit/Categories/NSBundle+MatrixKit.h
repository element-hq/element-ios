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
