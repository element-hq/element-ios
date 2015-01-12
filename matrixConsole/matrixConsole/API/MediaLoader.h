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

// Provide the download progress
// object: URL
// userInfo: kMediaLoaderProgressRateKey : progress value nested in a NSNumber (range 0->1)
//         : kMediaLoaderProgressStringKey : progress string XXX KB / XXX MB" (optional)
//         : kMediaLoaderProgressRemaingTimeKey : remaining time string "XX s left" (optional)
//         : kMediaLoaderProgressDownloadRateKey : string like XX MB/s (optional)
extern NSString *const kMediaDownloadProgressNotification;

// Provide the upload progress
// object: uploadId
// userInfo: kMediaLoaderProgressRateKey : progress value nested in a NSNumber (range 0->1)
//         : kMediaLoaderProgressStringKey : progress string XXX KB / XXX MB" (optional)
//         : kMediaLoaderProgressRemaingTimeKey : remaining time string "XX s left" (optional)
//         : kMediaLoaderProgressDownloadRateKey : string like XX MB/s (optional)
extern NSString *const kMediaUploadProgressNotification;

// userInfo keys
extern NSString *const kMediaLoaderProgressRateKey;
extern NSString *const kMediaLoaderProgressStringKey;
extern NSString *const kMediaLoaderProgressRemaingTimeKey;
extern NSString *const kMediaLoaderProgressDownloadRateKey;

// The callback blocks
typedef void (^blockMediaLoader_onSuccess)(NSString *url); // url is a cache file path for successful download, or a remote url for upload.
typedef void (^blockMediaLoader_onError)(NSError *error);

@interface MediaLoader : NSObject <NSURLConnectionDataDelegate> {
    NSString *mimeType;
    
    blockMediaLoader_onSuccess onSuccess;
    blockMediaLoader_onError onError;
    
    // Download
    NSString *mediaURL;
    long long expectedSize;
    NSMutableData *downloadData;
    NSURLConnection *downloadConnection;
    
    // statistic info (bitrate, remaining time...)
    CFAbsoluteTime statsStartTime;
    CFAbsoluteTime downloadStartTime;
    CFAbsoluteTime lastProgressEventTimeStamp;
    NSTimer* progressCheckTimer;
    
    // Upload
    NSString *uploadId;
    CGFloat initialRange;
    CGFloat range;
}

@property (strong, readonly) NSMutableDictionary* statisticsDict;

- (void)cancel;

// Download
- (void)downloadMedia:(NSString *)aMediaURL
             mimeType:(NSString *)aMimeType
              success:(blockMediaLoader_onSuccess)success
              failure:(blockMediaLoader_onError)failure;

// Upload
// initialRange / range: an upload could be a subpart of uploads. initialRange defines the global upload progress already did done before this current upload.
// range is the range value of this upload in the global scope.
// e.g. : Upload a media can be split in two parts :
// 1 - upload the thumbnail -> initialRange = 0, range = 0.1 : assume that the thumbnail upload is 10% of the upload process
// 2 - upload the media -> initialRange = 0.1, range = 0.9 : the media upload is 90% of the global upload
- (id)initWithUploadId:(NSString *)anUploadId initialRange:(CGFloat)anInitialRange andRange:(CGFloat)aRange;
- (void)uploadData:(NSData *)data
          mimeType:(NSString *)aMimeType
           success:(blockMediaLoader_onSuccess)success
           failure:(blockMediaLoader_onError)failure;

@end
