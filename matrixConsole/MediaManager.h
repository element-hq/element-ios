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
#import <UIKit/UIKit.h>

extern NSString *const kMediaManagerPrefixForDummyURL;

extern NSString *const kMediaManagerProgressRateKey;
extern NSString *const kMediaManagerProgressStringKey;
extern NSString *const kMediaManagerProgressRemaingTimeKey;
extern NSString *const kMediaManagerProgressDownloadRateKey;

// provide the download/upload progress
// object: URL
// userInfo: kMediaManagerProgressRateKey : progress value nested in a NSNumber (range 0->1)
//         : kMediaManagerProgressStringKey : progress string XXX KB / XXX MB" (optional)
//         : kMediaManagerProgressRemaingTimeKey : remaining time string "XX s left" (optional)
//         : kMediaManagerProgressDownloadRateKey : string like XX MB/s (optional)

extern NSString *const kMediaDownloadProgressNotification;
extern NSString *const kMediaUploadProgressNotification;

// notify when a media download is finished
// object: URL
extern NSString *const kMediaDownloadDidFinishNotification;
extern NSString *const kMediaDownloadDidFailNotification;

// The callback blocks
typedef void (^blockMediaManager_onMediaReady)(NSString *cacheFilePath);
typedef void (^blockMediaManager_onError)(NSError *error);

@interface MediaManager : NSObject

+ (id)sharedInstance;

+ (UIImage *)resize:(UIImage *)image toFitInSize:(CGSize)size;

// Load a picture from the local cache (Do not start any remote requests)
+ (UIImage*)loadCachePicture:(NSString*)pictureURL;

// Launch picture downloading. Return a mediaLoader reference in order to let the user cancel this action.
+ (id)downloadPicture:(NSString*)pictureURL;

// Prepare a media from the local cache or download it if it is not available yet.
// In this second case a mediaLoader reference is returned in order to let the user cancel this action.
+ (id)prepareMedia:(NSString *)mediaURL
          mimeType:(NSString *)mimeType
           success:(blockMediaManager_onMediaReady)success
        failure:(blockMediaManager_onError)failure;

// try to find out a media loder from a media URL
+ (id)mediaLoaderForURL:(NSString*)url;

// same dictionary as the kMediaDownloadProgressNotification one
+ (NSDictionary*)downloadStatsDict:(id)mediaLoader;

// cancel a media loader
+ (void)cancel:(id)mediaLoader;

+ (NSString *)cacheMediaData:(NSData *)mediaData forURL:(NSString *)mediaURL mimeType:(NSString *)mimeType;

+ (void)clearCache;

@end
