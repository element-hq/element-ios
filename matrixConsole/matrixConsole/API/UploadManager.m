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

#import "UploadManager.h"
#import "MediaManager.h"

NSString *const kUploadManagerUploadStartTimeKey = @"kUploadManagerUploadStartTimeKey";
NSString *const kUploadManagerStatsStartTimeKey = @"kUploadManagerUploadStartTimeKey";

@implementation UploadManager

// Table of stats dictionry by media URL
static NSMutableDictionary* statsByURL = nil;

// trigger the kMediaUploadProgressNotification notification from the upload parameters
// URL : the uploading media URL
// bytesWritten / totalBytesWritten / totalBytesExpectedToWrite : theses parameters are provided by NSURLConnectionDelegate
// initialRange / range: the current upload info could be a subpart of uploads. initialRange defines the global upload progress already did done before this current upload.
// range is the range value of this upload in the global scope.
// e.g. : Upload a media can be split in two parts :
// 1 - upload the thumbnail -> initialRange = 0, range = 0.1 : assume that the thumbnail upload is 10% of the upload process
// 2 - upload the media -> initialRange = 0,1, range = 0.9 : the media upload is 90% of the global upload
+ (void) onUploadProgress:(NSString*)URL bytesWritten:(NSUInteger)bytesWritten  totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite  initialRange:(CGFloat)initialRange  range:(CGFloat)range {
    
    // sanity check
    if (!URL) {
        // should never happen
        return;
    }
    
    if (!statsByURL) {
        statsByURL = [[NSMutableDictionary alloc] init];
    }
    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    
    NSMutableDictionary* dict = [statsByURL valueForKey:URL];
    
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
    
        // init the start times
        [dict setValue:[NSNumber numberWithDouble:currentTime] forKey:kUploadManagerUploadStartTimeKey];
        [dict setValue:[NSNumber numberWithDouble:currentTime] forKey:kUploadManagerStatsStartTimeKey];
        
        [statsByURL setValue:dict forKey:URL];
    }
    
    CGFloat progressRate = initialRange + (((float)totalBytesWritten) /  ((float)totalBytesExpectedToWrite) * range);
    
    [dict setValue:[NSNumber numberWithFloat:progressRate] forKey:kMediaLoaderProgressRateKey];
    
    CGFloat dataRate = 0;
    CFAbsoluteTime statsStartTime = ((NSNumber*)[dict valueForKey:kUploadManagerStatsStartTimeKey]).doubleValue;
    
    if (currentTime != statsStartTime)
    {
        dataRate = bytesWritten / 1024.0 / (currentTime - statsStartTime);
    }
    else
    {
        dataRate = bytesWritten / 1024.0 / 0.001;
    }
    
    CGFloat dataRemainingTime = 0;
    
    if (0 != dataRate)
    {
        dataRemainingTime = (totalBytesExpectedToWrite - totalBytesWritten)/ 1024.0 / dataRate;
    }
    
    NSString* progressString = [NSString stringWithFormat:@"%@ / %@", [NSByteCountFormatter stringFromByteCount:totalBytesWritten countStyle:NSByteCountFormatterCountStyleFile], [NSByteCountFormatter stringFromByteCount:totalBytesExpectedToWrite countStyle:NSByteCountFormatterCountStyleFile]];
    [dict setValue:progressString forKey:kMediaLoaderProgressStringKey];
    
    [dict setValue:[MediaManager formatSecondsInterval:dataRemainingTime] forKey:kMediaLoaderProgressRemaingTimeKey];
    
    NSString* downloadRateStr = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:dataRate * 1024 countStyle:NSByteCountFormatterCountStyleFile]];
    [dict setValue:downloadRateStr forKey:kMediaLoaderProgressDownloadRateKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaUploadProgressNotification object:URL userInfo:dict];
}

// returns the stats info with kMediaLoaderProgress... key
+ (NSDictionary*)statsInfoForURL:(NSString*)URL {
    // sanity check
    if (URL) {
        return [statsByURL valueForKey:URL];
    }
    return nil;
}

// the upload
+ (void)removeURL:(NSString*)URL {
    if (URL) {
        [statsByURL removeObjectForKey:URL];
    }
}

@end