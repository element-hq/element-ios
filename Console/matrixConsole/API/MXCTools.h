/*
 Copyright 2014 OpenMarket Ltd
 
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

@interface MXCTools : NSObject

// Time interval
+ (NSString*)formatSecondsInterval:(CGFloat)secondsInterval;

#pragma mark - File
+ (long long)folderSize:(NSString *)folderPath;

// return the list of files by name
// isTimeSorted : the files are sorted by creation date from the oldest to the most recent one
// largeFilesFirst: move the largest file to the list head (large > 100KB). It can be combined isTimeSorted
+ (NSArray*)listFiles:(NSString *)folderPath timeSorted:(BOOL)isTimeSorted largeFilesFirst:(BOOL)largeFilesFirst;

// return the file extension from a contentType
+ (NSString*)fileExtensionFromContentType:(NSString*)contentType;

#pragma mark - Image
+ (UIImage*)forceImageOrientationUp:(UIImage*)imageSrc;
+ (UIImage *)resize:(UIImage *)image toFitInSize:(CGSize)size;
+ (UIImageOrientation)imageOrientationForRotationAngleInDegree:(NSInteger)angle;

@end
