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

#import "MediaManager.h"
#import "MatrixHandler.h"

NSString *const kMediaDownloadProgressNotification = @"kMediaDownloadProgressNotification";
NSString *const kMediaUploadProgressNotification = @"kMediaUploadProgressNotification";

NSString *const kMediaLoaderProgressRateKey = @"kMediaLoaderProgressRateKey";
NSString *const kMediaLoaderProgressStringKey = @"kMediaLoaderProgressStringKey";
NSString *const kMediaLoaderProgressRemaingTimeKey = @"kMediaLoaderProgressRemaingTimeKey";
NSString *const kMediaLoaderProgressDownloadRateKey = @"kMediaLoaderProgressDownloadRateKey";

@implementation MediaLoader

@synthesize downloadStatsDict;

- (NSString*)validateContentURL:(NSString*)contentURL {
    // Detect matrix content url
    if ([contentURL hasPrefix:MX_PREFIX_CONTENT_URI]) {
        NSString *mxMediaPrefix = [NSString stringWithFormat:@"%@%@/download/", [[MatrixHandler sharedHandler] homeServerURL], kMXMediaPathPrefix];
        // Set actual url
        return [contentURL stringByReplacingOccurrencesOfString:MX_PREFIX_CONTENT_URI withString:mxMediaPrefix];
    }
    
    return contentURL;
}

- (void)downloadMedia:(NSString*)aMediaURL
             mimeType:(NSString *)aMimeType
                success:(blockMediaLoader_onMediaReady)success
                failure:(blockMediaLoader_onError)failure {
    // Report provided params
    mediaURL = aMediaURL;
    mimeType = aMimeType;
    onMediaReady = success;
    onError = failure;
    
    downloadStartTime = statsStartTime = CFAbsoluteTimeGetCurrent();
    lastProgressEventTimeStamp = -1;
    
    // Start downloading
    NSURL *url = [NSURL URLWithString:[self validateContentURL:aMediaURL]];
    downloadData = [[NSMutableData alloc] init];
    downloadConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
}

- (void)cancel {
    // Cancel potential connection
    if (downloadConnection) {
        NSLog(@"Image download has been cancelled (%@)", mediaURL);
        if (onError){
            onError(nil);
        }
        // Reset blocks
        onMediaReady = nil;
        onError = nil;
        [downloadConnection cancel];
        downloadConnection = nil;
        downloadData = nil;
    }
    else {
        // Reset blocks
        onMediaReady = nil;
        onError = nil;
    }
}

- (void)dealloc {
    [self cancel];
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    expectedSize = response.expectedContentLength;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"ERROR: media download failed: %@, %@", error, mediaURL);
    // send the latest known upload info
    [self progressCheckTimeout:nil];
    downloadStatsDict = nil;
    if (onError) {
        onError (error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append data
    [downloadData appendData:data];
    
    if (expectedSize > 0) {
        //
        float rate = ((float)downloadData.length) /  ((float)expectedSize);
       
        // should never happen
        if (rate > 1) {
            rate = 1.0;
        }
        
        CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
        CGFloat deltaTime = currentTime - statsStartTime;
        // in KB
        float dataRate;
        
        if (deltaTime > 0)
        {
            dataRate = ((CGFloat)data.length) / deltaTime / 1024.0;
        }
        else // avoid zero div error
        {
            dataRate = ((CGFloat)data.length) / (0.001) / 1024.0;
        }
        
        CGFloat meanRate = downloadData.length / (currentTime - downloadStartTime)/ 1024.0;
        CGFloat dataRemainingTime = 0;
        
        if (0 != meanRate)
        {
            dataRemainingTime = ((expectedSize - downloadData.length) / 1024.0) / meanRate;
        }
        
        statsStartTime = currentTime;

        // build the user info dictionary
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
        [dict setValue:[NSNumber numberWithFloat:rate] forKey:kMediaLoaderProgressRateKey];
        
        NSString* progressString = [NSString stringWithFormat:@"%@ / %@", [NSByteCountFormatter stringFromByteCount:downloadData.length countStyle:NSByteCountFormatterCountStyleFile], [NSByteCountFormatter stringFromByteCount:expectedSize countStyle:NSByteCountFormatterCountStyleFile]];
        [dict setValue:progressString forKey:kMediaLoaderProgressStringKey];
                
        [dict setValue:[MediaManager formatSecondsInterval:dataRemainingTime] forKey:kMediaLoaderProgressRemaingTimeKey];
        
        NSString* downloadRateStr = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:meanRate * 1024 countStyle:NSByteCountFormatterCountStyleFile]];
        [dict setValue:downloadRateStr forKey:kMediaLoaderProgressDownloadRateKey];
        
        downloadStatsDict = dict;
        
        // after 0.1s, resend the progress info
        // the upload can be stuck
        [progressCheckTimer invalidate];
        progressCheckTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progressCheckTimeout:) userInfo:self repeats:NO];
        
        // trigger the event only each 0.1s to avoid send to many events
        if ((lastProgressEventTimeStamp == -1) || ((currentTime - lastProgressEventTimeStamp) > 0.1)) {
            lastProgressEventTimeStamp = currentTime;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadProgressNotification object:mediaURL userInfo:downloadStatsDict];
        }
    }
}

- (IBAction)progressCheckTimeout:(id)sender {
    // remove the bitrate -> can be invalid
    [downloadStatsDict removeObjectForKey:kMediaLoaderProgressDownloadRateKey];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadProgressNotification object:mediaURL userInfo:downloadStatsDict];
    [progressCheckTimer invalidate];
    progressCheckTimer = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // send the latest known upload info
    [self progressCheckTimeout:nil];
    downloadStatsDict = nil;
    
    if (downloadData.length) {
        // Cache the downloaded data
        NSString *cacheFilePath = [MediaManager cacheMediaData:downloadData forURL:mediaURL mimeType:mimeType];
        // Call registered block
        if (onMediaReady) {
            onMediaReady(cacheFilePath);
        }
    } else {
        NSLog(@"ERROR: media download failed: %@", mediaURL);
        if (onError){
            onError(nil);
        }
    }
    
    downloadData = nil;
    downloadConnection = nil;
}

@end