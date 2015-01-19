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
extern NSString *const kMediaManagerThumbnailFolder;

// notify when a media download is finished (object: URL)
extern NSString *const kMediaDownloadDidFinishNotification;
extern NSString *const kMediaDownloadDidFailNotification;

@interface MediaManager : NSObject

// Download data from the provided URL. Return a mediaLoader reference in order to let the user cancel this action.
+ (MediaLoader*)downloadMediaFromURL:(NSString *)mediaURL withType:(NSString *)mimeType inFolder:(NSString*)folder;
// Check whether a download is already running for this media url. Return loader if any
+ (MediaLoader*)existingDownloaderForURL:(NSString*)url inFolder:(NSString*)folder;
// cancel any pending download, within the folder
+ (void)cancelDownloadsInFolder:(NSString*)folder;
// cancel any pending download
+ (void)cancelDownloads;

// Prepares and returns a media loader to upload data to matrix content repository.
// initialRange / range: an upload could be a subpart of uploads. initialRange defines the global upload progress already did done before this current upload.
// range is the range value of this upload in the global scope.
// e.g. : Upload a media can be split in two parts :
// 1 - upload the thumbnail -> initialRange = 0, range = 0.1 : assume that the thumbnail upload is 10% of the upload process
// 2 - upload the media -> initialRange = 0.1, range = 0.9 : the media upload is 90% of the global upload
+ (MediaLoader*)prepareUploaderWithId:(NSString *)uploadId initialRange:(CGFloat)initialRange andRange:(CGFloat)range inFolder:(NSString*)folder;
// Check whether an upload is already running with this id. Return loader if any
+ (MediaLoader*)existingUploaderWithId:(NSString*)uploadId inFolder:(NSString*)folder;
+ (void)removeUploaderWithId:(NSString*)uploadId inFolder:(NSString*)folder;
// cancel pending MediaLoader in folder
+ (void)cancelUploadsInFolder:(NSString*)folder;
// cancel any pending upload
+ (void)cancelUploads;

// Load a picture from the local cache (Do not start any remote requests)
+ (UIImage*)loadCachePictureForURL:(NSString*)pictureURL inFolder:(NSString*)folder;
// Store in cache the provided data for the media URL, return the path of the resulting file
+ (NSString*)cacheMediaData:(NSData *)mediaData forURL:(NSString *)mediaURL andType:(NSString *)mimeType inFolder:(NSString*)folder;
// Return the cache path deduced from media URL and type
+ (NSString*)cachePathForMediaURL:(NSString*)mediaURL andType:(NSString *)mimeType inFolder:(NSString*)folder;

// cache size management (values are in bytes)
+ (NSUInteger)cacheSize;
+ (NSUInteger)minCacheSize;
+ (NSUInteger)currentMaxCacheSize;
+ (void)setCurrentMaxCacheSize:(NSUInteger)maxCacheSize;
+ (NSUInteger)maxAllowedCacheSize;

+ (void)clearCache;
@end
