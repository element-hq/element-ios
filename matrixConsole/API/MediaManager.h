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

+ (UIImage *)resize:(UIImage *)image toFitInSize:(CGSize)size;

// Load a picture from the local cache (Do not start any remote requests)
+ (UIImage*)loadCachePicture:(NSString*)pictureURL;

// Launch picture downloading. Return a mediaLoader reference in order to let the user cancel this action.
+ (MediaLoader*)downloadPicture:(NSString*)pictureURL;

// Prepare a media from the local cache or download it if it is not available yet.
// In this second case a mediaLoader reference is returned in order to let the user cancel this action.
+ (MediaLoader*)prepareMedia:(NSString *)mediaURL
          mimeType:(NSString *)mimeType
           success:(blockMediaLoader_onMediaReady)success
        failure:(blockMediaLoader_onError)failure;

// Check whether a media loader is already running for this media url. Return loader if any
+ (MediaLoader*)mediaLoaderForURL:(NSString*)url;

+ (NSString *)cacheMediaData:(NSData *)mediaData forURL:(NSString *)mediaURL mimeType:(NSString *)mimeType;

+ (void)clearCache;

@end
