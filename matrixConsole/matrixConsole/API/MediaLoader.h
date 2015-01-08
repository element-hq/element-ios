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

// provide the download/upload progress
// object: URL
// userInfo: kMediaLoaderProgressRateKey : progress value nested in a NSNumber (range 0->1)
//         : kMediaLoaderProgressStringKey : progress string XXX KB / XXX MB" (optional)
//         : kMediaLoaderProgressRemaingTimeKey : remaining time string "XX s left" (optional)
//         : kMediaLoaderProgressDownloadRateKey : string like XX MB/s (optional)
extern NSString *const kMediaDownloadProgressNotification;
extern NSString *const kMediaUploadProgressNotification;
// userInfo keys
extern NSString *const kMediaLoaderProgressRateKey;
extern NSString *const kMediaLoaderProgressStringKey;
extern NSString *const kMediaLoaderProgressRemaingTimeKey;
extern NSString *const kMediaLoaderProgressDownloadRateKey;

// The callback blocks
typedef void (^blockMediaLoader_onMediaReady)(NSString *cacheFilePath);
typedef void (^blockMediaLoader_onError)(NSError *error);

@interface MediaLoader : NSObject <NSURLConnectionDataDelegate> {
    NSString *mediaURL;
    NSString *mimeType;
    
    blockMediaLoader_onMediaReady onMediaReady;
    blockMediaLoader_onError onError;
    
    long long expectedSize;
    
    NSMutableData *downloadData;
    NSURLConnection *downloadConnection;
    
    // statistic info (bitrate, remaining time...)
    CFAbsoluteTime statsStartTime;
    CFAbsoluteTime downloadStartTime;
    CFAbsoluteTime lastProgressEventTimeStamp;
    NSTimer* progressCheckTimer;
}

@property (strong, readonly) NSMutableDictionary* downloadStatsDict;

- (void)downloadMedia:(NSString*)aMediaURL
             mimeType:(NSString *)aMimeType
              success:(blockMediaLoader_onMediaReady)success
              failure:(blockMediaLoader_onError)failure;

- (void)cancel;

@end
