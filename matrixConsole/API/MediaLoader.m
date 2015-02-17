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
#import "MXCTools.h"

NSString *const kMediaDownloadProgressNotification = @"kMediaDownloadProgressNotification";
NSString *const kMediaUploadProgressNotification = @"kMediaUploadProgressNotification";

NSString *const kMediaLoaderProgressRateKey = @"kMediaLoaderProgressRateKey";
NSString *const kMediaLoaderProgressStringKey = @"kMediaLoaderProgressStringKey";
NSString *const kMediaLoaderProgressRemaingTimeKey = @"kMediaLoaderProgressRemaingTimeKey";
NSString *const kMediaLoaderProgressDownloadRateKey = @"kMediaLoaderProgressDownloadRateKey";

@implementation MediaLoader

@synthesize statisticsDict;

- (void)cancel {
    // Cancel potential connection
    if (downloadConnection) {
        NSLog(@"media download has been cancelled (%@)", mediaURL);
        if (onError){
            onError(nil);
        }
        // Reset blocks
        onSuccess = nil;
        onError = nil;
        [downloadConnection cancel];
        downloadConnection = nil;
        downloadData = nil;
    }
    else {
        if (operation.operation.executing) {
            NSLog(@"media upload has been cancelled (%@)", mediaURL);
            [operation cancel];
            operation = nil;
        }

        // Reset blocks
        onSuccess = nil;
        onError = nil;
    }
    folder = nil;
    statisticsDict = nil;
}

- (void)dealloc {
    [self cancel];
}

#pragma mark - Download

- (void)downloadMedia:(NSString*)aMediaURL
             mimeType:(NSString *)aMimeType
               folder:(NSString*)aFolder
              success:(blockMediaLoader_onSuccess)success
              failure:(blockMediaLoader_onError)failure {
    // Report provided params
    mediaURL = aMediaURL;
    mimeType = aMimeType;
    folder = aFolder;
    onSuccess = success;
    onError = failure;
    
    downloadStartTime = statsStartTime = CFAbsoluteTimeGetCurrent();
    lastProgressEventTimeStamp = -1;
    
    // Check provided url (it may be a matrix content uri, we use SDK to build absoluteURL)
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    NSString *absoluteMediaURL = [mxHandler.mxRestClient urlOfContent:aMediaURL];
    if (nil == absoluteMediaURL) {
        // It was not a matrix content uri, we keep the provided url
        absoluteMediaURL = aMediaURL;
    }
    
    // Start downloading
    NSURL *url = [NSURL URLWithString:absoluteMediaURL];
    downloadData = [[NSMutableData alloc] init];
    
    downloadConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    expectedSize = response.expectedContentLength;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"ERROR: media download failed: %@, %@", error, mediaURL);
    // send the latest known upload info
    [self progressCheckTimeout:nil];
    statisticsDict = nil;
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
                
        [dict setValue:[MXCTools formatSecondsInterval:dataRemainingTime] forKey:kMediaLoaderProgressRemaingTimeKey];
        
        NSString* downloadRateStr = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:meanRate * 1024 countStyle:NSByteCountFormatterCountStyleFile]];
        [dict setValue:downloadRateStr forKey:kMediaLoaderProgressDownloadRateKey];
        
        statisticsDict = dict;
        
        // after 0.1s, resend the progress info
        // the upload can be stuck
        [progressCheckTimer invalidate];
        progressCheckTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progressCheckTimeout:) userInfo:self repeats:NO];
        
        // trigger the event only each 0.1s to avoid send to many events
        if ((lastProgressEventTimeStamp == -1) || ((currentTime - lastProgressEventTimeStamp) > 0.1)) {
            lastProgressEventTimeStamp = currentTime;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadProgressNotification object:mediaURL userInfo:statisticsDict];
        }
    }
}

- (IBAction)progressCheckTimeout:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadProgressNotification object:mediaURL userInfo:statisticsDict];
    [progressCheckTimer invalidate];
    progressCheckTimer = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // send the latest known upload info
    [self progressCheckTimeout:nil];
    statisticsDict = nil;
    
    if (downloadData.length) {
        // Cache the downloaded data
        NSString *cacheFilePath = [MediaManager cacheMediaData:downloadData forURL:mediaURL andType:mimeType inFolder:folder];
        // Call registered block
        if (onSuccess) {
            onSuccess(cacheFilePath);
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

#pragma mark - Upload

- (id)initWithUploadId:(NSString *)anUploadId initialRange:(CGFloat)anInitialRange andRange:(CGFloat)aRange folder:(NSString*)aFolder {
    if (self = [super init]) {
        uploadId = anUploadId;
        initialRange = anInitialRange;
        range = aRange;
        folder = aFolder;
    }
    return self;
}

- (void)uploadData:(NSData *)data mimeType:(NSString *)aMimeType success:(blockMediaLoader_onSuccess)success failure:(blockMediaLoader_onError)failure {
    mimeType = aMimeType;
    statsStartTime = CFAbsoluteTimeGetCurrent();
    
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    operation = [mxHandler.mxRestClient uploadContent:data mimeType:mimeType timeout:30 success:success failure:failure uploadProgress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        [self updateUploadProgressWithBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten andTotalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }];
    
}

- (void)updateUploadProgressWithBytesWritten:(NSUInteger)bytesWritten totalBytesWritten:(long long)totalBytesWritten andTotalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite {
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    if (!statisticsDict) {
        statisticsDict = [[NSMutableDictionary alloc] init];
    }
    
    CGFloat progressRate = initialRange + (((float)totalBytesWritten) /  ((float)totalBytesExpectedToWrite) * range);
    
    [statisticsDict setValue:[NSNumber numberWithFloat:progressRate] forKey:kMediaLoaderProgressRateKey];
    
    CGFloat dataRate = 0;
    if (currentTime != statsStartTime)
    {
        dataRate = bytesWritten / 1024.0 / (currentTime - statsStartTime);
    }
    else
    {
        dataRate = bytesWritten / 1024.0 / 0.001;
    }
    statsStartTime = currentTime;
    
    CGFloat dataRemainingTime = 0;
    if (0 != dataRate)
    {
        dataRemainingTime = (totalBytesExpectedToWrite - totalBytesWritten)/ 1024.0 / dataRate;
    }
    
    NSString* progressString = [NSString stringWithFormat:@"%@ / %@", [NSByteCountFormatter stringFromByteCount:totalBytesWritten countStyle:NSByteCountFormatterCountStyleFile], [NSByteCountFormatter stringFromByteCount:totalBytesExpectedToWrite countStyle:NSByteCountFormatterCountStyleFile]];
    
    [statisticsDict setValue:progressString forKey:kMediaLoaderProgressStringKey];
    [statisticsDict setValue:[MXCTools formatSecondsInterval:dataRemainingTime] forKey:kMediaLoaderProgressRemaingTimeKey];
    
    NSString* downloadRateStr = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:dataRate * 1024 countStyle:NSByteCountFormatterCountStyleFile]];
    [statisticsDict setValue:downloadRateStr forKey:kMediaLoaderProgressDownloadRateKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaUploadProgressNotification object:uploadId userInfo:statisticsDict];
}

@end