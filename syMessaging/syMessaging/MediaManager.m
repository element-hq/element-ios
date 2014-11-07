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

static NSString* pictureCachePath  = nil;
static NSString *pictureDir        = @"picturecache";

static MediaManager *sharedMediaManager = nil;

@interface MediaLoader : NSObject <NSURLConnectionDataDelegate> {
    NSString *mediaURL;
    
    blockMediaManager_onImageReady onImageReady;
    blockMediaManager_onError onError;
    
    NSMutableData *downloadData;
    NSURLConnection *downloadConnection;
}
@end

@implementation MediaLoader

- (void)downloadPicture:(NSString*)pictureURL
             success:(blockMediaManager_onImageReady)success
             failure:(blockMediaManager_onError)failure {
    // Report provided params
    mediaURL = pictureURL;
    onImageReady = success;
    onError = failure;
    
    // Start downloading the picture
    NSURL *url = [NSURL URLWithString:pictureURL];
    downloadData = [[NSMutableData alloc] init];
    downloadConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:self];
}

- (void)cancel
{
    // Reset blocks
    onImageReady = nil;
    onError = nil;
    // Cancel potential connection
    if (downloadConnection) {
        [downloadConnection cancel];
        downloadConnection = nil;
        downloadData = nil;
    }
}

- (void)dealloc
{
    [self cancel];
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"ERROR: picture download failed: %@, %@", error, mediaURL);
    if (onError) {
        onError (error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append data
    [downloadData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // CAUTION: Presently only picture are supported
    // Set downloaded image
    UIImage *image = [UIImage imageWithData:downloadData];
    if (image) {
        // Cache the downloaded data
        [MediaManager cachePictureWithData:downloadData forURL:mediaURL];
        // Call registered block
        if (onImageReady) {
            onImageReady(image);
        }
    } else {
        NSLog(@"ERROR: picture download failed: %@", mediaURL);
        if (onError){
            onError(nil);
        }
    }
    
    downloadData = nil;
    downloadConnection = nil;
}

@end

@implementation MediaManager

+ (id)sharedInstance {
    @synchronized(self) {
        if(sharedMediaManager == nil)
            sharedMediaManager = [[self alloc] init];
    }
    return sharedMediaManager;
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
    else {
        // Create a media loader to download picture
        MediaLoader *mediaLoader = [[MediaLoader alloc] init];
        [mediaLoader downloadPicture:pictureURL success:success failure:failure];
        ret = mediaLoader;
    }
    return ret;
}

+ (void)cancel:(id)mediaLoader {
    [((MediaLoader*)mediaLoader) cancel];
}

#pragma mark - Cache handling

+ (NSString*)cachePictureWithData:(NSData*)imageData forURL:(NSString *)pictureURL {
    NSString* filename = [MediaManager getCacheFileNameFor:pictureURL];
    
    if ([imageData writeToFile:filename atomically:YES]) {
        return filename;
    } else {
        return nil;
    }
}

+ (UIImage*)loadCachePicture:(NSString*)pictureURL {
    UIImage* res = nil;
    NSString* filename = [MediaManager getCacheFileNameFor:pictureURL];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        NSData* imageContent = [NSData dataWithContentsOfFile:filename options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
        if (imageContent) {
            res = [[UIImage alloc] initWithData:imageContent];
        }
    }
    
    return res;
}

+ (NSString*)getCachePath {
    NSString *mediaCachePath = nil;
    
    if (!pictureCachePath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheRoot = [paths objectAtIndex:0];
        
        pictureCachePath = [cacheRoot stringByAppendingPathComponent:pictureDir];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:pictureCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:pictureCachePath withIntermediateDirectories:NO attributes:nil error:nil];
        }
    }
    mediaCachePath = pictureCachePath;
    
    return mediaCachePath;
}

+ (NSString*)getCacheFileNameFor:(NSString*)pictureURL {
    NSString* baseFileName = [[MediaManager getCachePath] stringByAppendingPathComponent:@"ima"];
    return [NSString stringWithFormat:@"%@%lu.jpg", baseFileName, (unsigned long)pictureURL.hash];
}

+ (void)clearCache {
    NSError *error = nil;
    
    if (!pictureCachePath) {
        // compute the path
        pictureCachePath = [MediaManager getCachePath];
    }
    
    if (pictureCachePath) {
        if (![[NSFileManager defaultManager] removeItemAtPath:pictureCachePath error:&error]) {
            NSLog(@"Fails to delete picture cache dir : %@", error);
        } else {
            NSLog(@"Picture cache : deleted !");
        }
    } else {
        NSLog(@"Picture cache does not exist");
    }
    
    pictureCachePath = nil;
}

@end
