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

#import <AVFoundation/AVFoundation.h>
#import "MediaLoader.h"

extern NSString *const kMediaManagerPrefixForDummyURL;

// notify when a media download is finished
// object: URL
extern NSString *const kMediaDownloadDidFinishNotification;
extern NSString *const kMediaDownloadDidFailNotification;

@interface MediaManager : NSObject

+ (id)sharedInstance;

// Launch data download from the provided URL. Return a mediaLoader reference in order to let the user cancel this action.
+ (MediaLoader*)downloadMedia:(NSString*)mediaURL mimeType:(NSString *)mimeType;
// Check whether a download is already running for this media url. Return loader if any
+ (MediaLoader*)existingDownloaderForURL:(NSString*)url;

// Load a picture from the local cache (Do not start any remote requests)
+ (UIImage*)loadCachePictureForURL:(NSString*)pictureURL;
// Store in cache the provided data for the media URL, return the path of the resulting file
+ (NSString*)cacheMediaData:(NSData *)mediaData forURL:(NSString *)mediaURL andType:(NSString *)mimeType;
// Return the cache path deduced from media URL and type
+ (NSString*)cachePathForMediaURL:(NSString*)mediaURL andType:(NSString *)mimeType;
+ (NSUInteger)cacheSize;
+ (void)clearCache;

@end
