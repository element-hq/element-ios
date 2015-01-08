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

NSString *const kMediaManagerPrefixForDummyURL = @"dummyUrl-";

NSString *const kMediaDownloadProgressNotification = @"kMediaDownloadProgressNotification";
NSString *const kMediaUploadProgressNotification = @"kMediaUploadProgressNotification";

NSString *const kMediaDownloadDidFinishNotification = @"kMediaDownloadDidFinishNotification";
NSString *const kMediaDownloadDidFailNotification = @"kMediaDownloadDidFailNotification";

NSString *const kMediaManagerProgressRateKey = @"kMediaManagerProgressRateKey";
NSString *const kMediaManagerProgressStringKey = @"kMediaManagerProgressStringKey";
NSString *const kMediaManagerProgressRemaingTimeKey = @"kMediaManagerProgressRemaingTimeKey";
NSString *const kMediaManagerProgressDownloadRateKey = @"kMediaManagerProgressDownloadRateKey";

static NSString* mediaCachePath  = nil;
static NSString *mediaDir        = @"mediacache";

static MediaManager *sharedMediaManager = nil;

@interface MediaLoader : NSObject <NSURLConnectionDataDelegate> {
    NSString *mediaURL;
    NSString *mimeType;
    
    blockMediaManager_onMediaReady onMediaReady;
    blockMediaManager_onError onError;
    
    long long expectedSize;
    
    NSMutableData *downloadData;
    NSURLConnection *downloadConnection;
    
    // statistic info (bitrate, remaining time...)
    CFAbsoluteTime statsStartTime;
    CFAbsoluteTime downloadStartTime;
    CFAbsoluteTime lastProgressEventTimeStamp;
    NSTimer* progressCheckTimer;
}

+ (MediaLoader*)mediaLoaderForURL:(NSString*)url;

@property (strong, nonatomic) NSMutableDictionary* downloadStatsDict;
@end

#pragma mark - MediaLoader

@implementation MediaLoader
@synthesize downloadStatsDict;

// find a MediaLoader
static NSMutableDictionary* pendingMediaLoadersByURL = nil;

+ (MediaLoader*)mediaLoaderForURL:(NSString*)url {
    MediaLoader* res = nil;
    
    if (pendingMediaLoadersByURL && url) {
        res = [pendingMediaLoadersByURL valueForKey:url];
    }
    
    return res;
}

+ (void) setMediaLoader:(MediaLoader*)mediaLoader forURL:(NSString*)url {
    if (!pendingMediaLoadersByURL) {
        pendingMediaLoadersByURL = [[NSMutableDictionary alloc] init];
    }
    
    // sanity check
    if (mediaLoader && url) {
        [pendingMediaLoadersByURL setValue:mediaLoader forKey:url];
    }
}

+ (void) removeMediaLoaderWithUrl:(NSString*)url {
    if (url) {
        [pendingMediaLoadersByURL removeObjectForKey:url];
    }
}

- (NSString*)validateContentURL:(NSString*)contentURL {
    // Detect matrix content url
    if ([contentURL hasPrefix:MX_PREFIX_CONTENT_URI]) {
        NSString *mxMediaPrefix = [NSString stringWithFormat:@"%@%@/download/", [[MatrixHandler sharedHandler] homeServerURL], kMXMediaPathPrefix];
        // Set actual url
        return [contentURL stringByReplacingOccurrencesOfString:MX_PREFIX_CONTENT_URI withString:mxMediaPrefix];
    }
    
    return contentURL;
}


- (void)downloadPicture:(NSString*)pictureURL
             success:(blockMediaManager_onImageReady)success
             failure:(blockMediaManager_onError)failure {
    
    [MediaLoader setMediaLoader:self forURL:pictureURL];
    
    // Download picture content
    [self downloadMedia:pictureURL mimeType:@"image/jpeg" success:^(NSString *cacheFilePath) {
        [MediaLoader removeMediaLoaderWithUrl:pictureURL];

        if (success) {
            NSData* imageContent = [NSData dataWithContentsOfFile:cacheFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            if (imageContent) {
                UIImage *image = [UIImage imageWithData:imageContent];
                if (image) {
                    success(image);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFinishNotification object:pictureURL userInfo:nil];
                } else {
                    NSLog(@"ERROR: picture download failed: %@", pictureURL);
                    if (failure){
                        [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:pictureURL userInfo:nil];
                        failure(nil);
                    }
                }
            }
        }
    } failure:^(NSError *error) {
        [MediaLoader removeMediaLoaderWithUrl:pictureURL];
        failure(error);
        NSLog(@"Failed to download image (%@): %@", pictureURL, error);
        [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:pictureURL userInfo:nil];
    }];
}

- (void)downloadMedia:(NSString*)aMediaURL
             mimeType:(NSString *)aMimeType
                success:(blockMediaManager_onMediaReady)success
                failure:(blockMediaManager_onError)failure {
    // Report provided params
    mediaURL = aMediaURL;
    mimeType = aMimeType;
    onMediaReady = success;
    onError = failure;
    
    downloadStartTime = statsStartTime = CFAbsoluteTimeGetCurrent();
    lastProgressEventTimeStamp = -1;
    
    [MediaLoader setMediaLoader:self forURL:mediaURL];
    
    // Start downloading
    NSURL *url = [NSURL URLWithString:[self validateContentURL:aMediaURL]];
    downloadData = [[NSMutableData alloc] init];
    downloadConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
}

- (void)cancel {
    [MediaLoader removeMediaLoaderWithUrl:mediaURL];
    // Reset blocks
    onMediaReady = nil;
    onError = nil;
    // Cancel potential connection
    if (downloadConnection) {
        [downloadConnection cancel];
        downloadConnection = nil;
        downloadData = nil;
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
    
    [MediaLoader removeMediaLoaderWithUrl:mediaURL];
    
    // send the latest known upload info
    [self progressCheckTimeout:nil];
    downloadStatsDict = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:mediaURL userInfo:nil];
    
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
        [dict setValue:[NSNumber numberWithFloat:rate] forKey:kMediaManagerProgressRateKey];
        
        NSString* progressString = [NSString stringWithFormat:@"%@ / %@", [NSByteCountFormatter stringFromByteCount:downloadData.length countStyle:NSByteCountFormatterCountStyleFile], [NSByteCountFormatter stringFromByteCount:expectedSize countStyle:NSByteCountFormatterCountStyleFile]];
        [dict setValue:progressString forKey:kMediaManagerProgressStringKey];
        
        NSMutableString* remaingTimeStr = [[NSMutableString alloc] init];
        
        if (dataRemainingTime < 1) {
            [remaingTimeStr appendString:@"< 1s"];
        } else if (dataRemainingTime < 60)
        {
            [remaingTimeStr appendFormat:@"%ds", (int)dataRemainingTime];
        }
        else if (dataRemainingTime < 3600)
        {
            [remaingTimeStr appendFormat:@"%dm %2ds", (int)(dataRemainingTime/60), ((int)dataRemainingTime) % 60];
        }
        else if (dataRemainingTime >= 3600)
        {
            [remaingTimeStr appendFormat:@"%dh %dm %ds", (int)(dataRemainingTime / 3600),
             ((int)(dataRemainingTime) % 3600) / 60,
             (int)(dataRemainingTime) % 60];
        }
        [remaingTimeStr appendString:@" left"];
        
        [dict setValue:remaingTimeStr forKey:kMediaManagerProgressRemaingTimeKey];
        
        NSString* downloadRateStr = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:meanRate * 1024 countStyle:NSByteCountFormatterCountStyleFile]];
        [dict setValue:downloadRateStr forKey:kMediaManagerProgressDownloadRateKey];
        
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

- (IBAction) progressCheckTimeout:(id)sender
{
    // remove the bitrate -> can be invalid
    [downloadStatsDict removeObjectForKey:kMediaManagerProgressDownloadRateKey];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadProgressNotification object:mediaURL userInfo:downloadStatsDict];
    [progressCheckTimer invalidate];
    progressCheckTimer = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [MediaLoader removeMediaLoaderWithUrl:mediaURL];
    
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFinishNotification object:mediaURL userInfo:nil];
    } else {
        NSLog(@"ERROR: media download failed: %@", mediaURL);
        if (onError){
            onError(nil);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:mediaURL userInfo:nil];
    }
    
    downloadData = nil;
    downloadConnection = nil;
}

@end

#pragma mark - MediaManager

@implementation MediaManager

+ (id)sharedInstance {
    @synchronized(self) {
        if(sharedMediaManager == nil)
            sharedMediaManager = [[self alloc] init];
    }
    return sharedMediaManager;
}

+ (UIImage *)resize:(UIImage *)image toFitInSize:(CGSize)size {
    UIImage *resizedImage = image;
    
    // Check whether resize is required
    if (size.width && size.height) {
        CGFloat width = image.size.width;
        CGFloat height = image.size.height;
        
        if (width > size.width) {
            height = (height * size.width) / width;
            height = floorf(height / 2) * 2;
            width = size.width;
        }
        if (height > size.height) {
            width = (width * size.height) / height;
            width = floorf(width / 2) * 2;
            height = size.height;
        }
        
        if (width != image.size.width || height != image.size.height) {
            // Create the thumbnail
            CGSize imageSize = CGSizeMake(width, height);
            UIGraphicsBeginImageContext(imageSize);
            
            CGRect thumbnailRect = CGRectMake(0, 0, 0, 0);
            thumbnailRect.origin = CGPointMake(0.0,0.0);
            thumbnailRect.size.width  = imageSize.width;
            thumbnailRect.size.height = imageSize.height;
            
            [image drawInRect:thumbnailRect];
            resizedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    
    return resizedImage;
}

// Load a picture from the local cache or download it if it is not available yet.
// In this second case a mediaLoader reference is returned in order to let the user cancel this action.
+ (id)loadPicture:(NSString*)pictureURL
          success:(blockMediaManager_onImageReady)success
          failure:(blockMediaManager_onError)failure {
    id ret = nil;
    // Check cached pictures
    UIImage *image = [MediaManager loadCachePicture:pictureURL];
    if (image) {
        if (success) {
            // Reply synchronously
            success (image);
        }
    }
    else if ([pictureURL hasPrefix:kMediaManagerPrefixForDummyURL] == NO) {
        // Create a media loader to download picture
        MediaLoader *mediaLoader = [[MediaLoader alloc] init];
        [mediaLoader downloadPicture:pictureURL success:success failure:failure];
        ret = mediaLoader;
    } else {
        NSLog(@"Load tmp picture from cache failed: %@", pictureURL);
        if (failure){
            failure(nil);
        }
    }
    return ret;
}

+ (id)prepareMedia:(NSString *)mediaURL
          mimeType:(NSString *)mimeType
           success:(blockMediaManager_onMediaReady)success
           failure:(blockMediaManager_onError)failure {
    id ret = nil;
    // Check cache
    NSString* filename = [MediaManager getCacheFileNameFor:mediaURL mimeType:mimeType];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        if (success) {
            // Reply synchronously
            success (filename);
        }
    }
    else if ([mediaURL hasPrefix:kMediaManagerPrefixForDummyURL] == NO) {
        // Create a media loader to download media content
        MediaLoader *mediaLoader = [[MediaLoader alloc] init];
        [mediaLoader downloadMedia:mediaURL mimeType:mimeType success:success failure:failure];
        ret = mediaLoader;
    } else {
        NSLog(@"Load tmp media from cache failed: %@", mediaURL);
        if (failure){
            failure(nil);
        }
    }
    return ret;
}

// try to find out a media loder from a media URL
+ (id)mediaLoaderForURL:(NSString*)url {
    return [MediaLoader mediaLoaderForURL:url];
}

+ (NSDictionary*)downloadStatsDict:(id)mediaLoader {
    return ((MediaLoader*)mediaLoader).downloadStatsDict;
}

+ (void)cancel:(id)mediaLoader {
    [((MediaLoader*)mediaLoader) cancel];
}

+ (NSString*)cacheMediaData:(NSData*)mediaData forURL:(NSString *)mediaURL mimeType:(NSString *)mimeType {
    NSString* filename = [MediaManager getCacheFileNameFor:mediaURL mimeType:mimeType];
    
    if ([mediaData writeToFile:filename atomically:YES]) {
        return filename;
    } else {
        return nil;
    }
}

+ (void)clearCache {
    NSError *error = nil;
    
    if (!mediaCachePath) {
        // compute the path
        mediaCachePath = [MediaManager getCachePath];
    }
    
    if (mediaCachePath) {
        if (![[NSFileManager defaultManager] removeItemAtPath:mediaCachePath error:&error]) {
            NSLog(@"Fails to delete media cache dir : %@", error);
        } else {
            NSLog(@"Media cache : deleted !");
        }
    } else {
        NSLog(@"Media cache does not exist");
    }
    
    mediaCachePath = nil;
}

#pragma mark - Cache handling

+ (UIImage*)loadCachePicture:(NSString*)pictureURL {
    UIImage* res = nil;
    NSString* filename = [MediaManager getCacheFileNameFor:pictureURL mimeType:@"image/jpeg"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        NSData* imageContent = [NSData dataWithContentsOfFile:filename options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
        if (imageContent) {
            res = [[UIImage alloc] initWithData:imageContent];
        }
    }
    
    return res;
}

+ (NSString*)getCachePath {
    NSString *cachePath = nil;
    
    if (!mediaCachePath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheRoot = [paths objectAtIndex:0];
        
        mediaCachePath = [cacheRoot stringByAppendingPathComponent:mediaDir];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:mediaCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:mediaCachePath withIntermediateDirectories:NO attributes:nil error:nil];
        }
    }
    cachePath = mediaCachePath;
    
    return cachePath;
}

+ (NSString*)getCacheFileNameFor:(NSString*)mediaURL mimeType:(NSString *)mimeType {
    NSString *fileName;
    if ([mimeType isEqualToString:@"image/jpeg"]) {
        fileName = [NSString stringWithFormat:@"ima%lu.jpg", (unsigned long)mediaURL.hash];
    } else if ([mimeType isEqualToString:@"video/mp4"]) {
        fileName = [NSString stringWithFormat:@"video%lu.mp4", (unsigned long)mediaURL.hash];
    } else if ([mimeType isEqualToString:@"video/quicktime"]) {
        fileName = [NSString stringWithFormat:@"video%lu.mov", (unsigned long)mediaURL.hash];
    } else {
        NSString *extension = @"";
        NSArray *components = [mediaURL componentsSeparatedByString:@"."];
        if (components && components.count > 1) {
            extension = [components lastObject];
        }
        fileName = [NSString stringWithFormat:@"%lu.%@", (unsigned long)mediaURL.hash, extension];
    }
    
    return [[MediaManager getCachePath] stringByAppendingPathComponent:fileName];
}

@end
