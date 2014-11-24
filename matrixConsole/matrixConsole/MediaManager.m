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

NSString *const kMediaManagerPrefixForDummyURL = @"dummyUrl-";

static NSString* mediaCachePath  = nil;
static NSString *mediaDir        = @"mediacache";

static MediaManager *sharedMediaManager = nil;

@interface MediaLoader : NSObject <NSURLConnectionDataDelegate> {
    NSString *mediaURL;
    NSString *mimeType;
    
    blockMediaManager_onMediaReady onMediaReady;
    blockMediaManager_onError onError;
    
    NSMutableData *downloadData;
    NSURLConnection *downloadConnection;
}
@end

#pragma mark - MediaLoader

@implementation MediaLoader

- (void)downloadPicture:(NSString*)pictureURL
             success:(blockMediaManager_onImageReady)success
             failure:(blockMediaManager_onError)failure {
    // Download picture content
    [self downloadMedia:pictureURL mimeType:@"image/jpeg" success:^(NSString *cacheFilePath) {
        if (success) {
            NSData* imageContent = [NSData dataWithContentsOfFile:cacheFilePath options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
            if (imageContent) {
                UIImage *image = [UIImage imageWithData:imageContent];
                if (image) {
                    success(image);
                } else {
                    NSLog(@"ERROR: picture download failed: %@", pictureURL);
                    if (failure){
                        failure(nil);
                    }
                }
            }
        }
    } failure:^(NSError *error) {
        failure(error);
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
    
    // Start downloading
    NSURL *url = [NSURL URLWithString:aMediaURL];
    downloadData = [[NSMutableData alloc] init];
    downloadConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
}

- (void)cancel {
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

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"ERROR: media download failed: %@, %@", error, mediaURL);
    if (onError) {
        onError (error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append data
    [downloadData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
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
