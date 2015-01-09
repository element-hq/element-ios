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

NSString *const kMediaDownloadDidFinishNotification = @"kMediaDownloadDidFinishNotification";
NSString *const kMediaDownloadDidFailNotification = @"kMediaDownloadDidFailNotification";

static NSString* mediaCachePath  = nil;
static NSString *mediaDir        = @"mediacache";

static MediaManager *sharedMediaManager = nil;

@implementation MediaManager

// Table of mediaLoaders in progress
static NSMutableDictionary* pendingMediaLoadersByURL = nil;

+ (id)sharedInstance {
    @synchronized(self) {
        if(sharedMediaManager == nil)
            sharedMediaManager = [[self alloc] init];
    }
    return sharedMediaManager;
}

+ (NSString*)formatSecondsInterval:(CGFloat)secondsInterval {
    NSMutableString* formattedString = [[NSMutableString alloc] init];
    
    if (secondsInterval < 1) {
        [formattedString appendString:@"< 1s"];
    } else if (secondsInterval < 60)
    {
        [formattedString appendFormat:@"%ds", (int)secondsInterval];
    }
    else if (secondsInterval < 3600)
    {
        [formattedString appendFormat:@"%dm %2ds", (int)(secondsInterval/60), ((int)secondsInterval) % 60];
    }
    else if (secondsInterval >= 3600)
    {
        [formattedString appendFormat:@"%dh %dm %ds", (int)(secondsInterval / 3600),
         ((int)(secondsInterval) % 3600) / 60,
         (int)(secondsInterval) % 60];
    }
    [formattedString appendString:@" left"];
    
    return formattedString;
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
            
//            // set to the top quality
//            CGContextRef context = UIGraphicsGetCurrentContext();
//            CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
            
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

+ (id)downloadPicture:(NSString*)pictureURL {
    if ([pictureURL hasPrefix:kMediaManagerPrefixForDummyURL] == NO) {
        // Create a media loader to download picture
        MediaLoader *mediaLoader = [[MediaLoader alloc] init];
        [self setMediaLoader:mediaLoader forURL:pictureURL];
        [mediaLoader downloadMedia:pictureURL mimeType:@"image/jpeg" success:^(NSString *cacheFilePath) {
            [self removeMediaLoaderWithUrl:pictureURL];
            [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFinishNotification object:pictureURL userInfo:nil];
        } failure:^(NSError *error) {
            [self removeMediaLoaderWithUrl:pictureURL];
            NSLog(@"Failed to download image (%@): %@", pictureURL, error);
            [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:pictureURL userInfo:nil];
        }];
        return mediaLoader;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:pictureURL userInfo:nil];
    return nil;
}

+ (id)prepareMedia:(NSString *)mediaURL
          mimeType:(NSString *)mimeType
           success:(blockMediaLoader_onMediaReady)success
           failure:(blockMediaLoader_onError)failure {
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

// try to find out a media loader from a media URL
+ (id)mediaLoaderForURL:(NSString*)url {
    if (pendingMediaLoadersByURL && url) {
        return [pendingMediaLoadersByURL valueForKey:url];
    }
    return nil;
}

+ (void)setMediaLoader:(MediaLoader*)mediaLoader forURL:(NSString*)url {
    if (!pendingMediaLoadersByURL) {
        pendingMediaLoadersByURL = [[NSMutableDictionary alloc] init];
    }
    
    // sanity check
    if (mediaLoader && url) {
        [pendingMediaLoadersByURL setValue:mediaLoader forKey:url];
    }
}

+ (void)removeMediaLoaderWithUrl:(NSString*)url {
    if (url) {
        [pendingMediaLoadersByURL removeObjectForKey:url];
    }
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
