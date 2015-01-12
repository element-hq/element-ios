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
static NSMutableDictionary* downloadTableByURL = nil;

+ (id)sharedInstance {
    @synchronized(self) {
        if(sharedMediaManager == nil) {
            sharedMediaManager = [[self alloc] init];
            // Create download table here
            downloadTableByURL = [[NSMutableDictionary alloc] init];
        }
    }
    return sharedMediaManager;
}

#pragma mark - Media Download

+ (MediaLoader*)downloadMedia:(NSString*)mediaURL mimeType:(NSString *)mimeType {
    if ([mediaURL hasPrefix:kMediaManagerPrefixForDummyURL] == NO) {
        // Create a media loader to download data
        MediaLoader *mediaLoader = [[MediaLoader alloc] init];
        // Report this loader
        [downloadTableByURL setValue:mediaLoader forKey:mediaURL];
        
        // Launch download
        [mediaLoader downloadMedia:mediaURL mimeType:mimeType success:^(NSString *cacheFilePath) {
            [downloadTableByURL removeObjectForKey:mediaURL];
            [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFinishNotification object:mediaURL userInfo:nil];
        } failure:^(NSError *error) {
            [downloadTableByURL removeObjectForKey:mediaURL];
            NSLog(@"Failed to download image (%@): %@", mediaURL, error);
            [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:mediaURL userInfo:nil];
        }];
        return mediaLoader;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:mediaURL userInfo:nil];
    return nil;
}

// try to find out a media loader from a media URL
+ (id)existingDownloaderForURL:(NSString*)url {
    if (downloadTableByURL && url) {
        return [downloadTableByURL valueForKey:url];
    }
    return nil;
}

#pragma mark - Cache Handling

+ (UIImage*)loadCachePictureForURL:(NSString*)pictureURL {
    UIImage* res = nil;
    NSString* filename = [MediaManager cachePathForMediaURL:pictureURL andType:@"image/jpeg"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        NSData* imageContent = [NSData dataWithContentsOfFile:filename options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
        if (imageContent) {
            res = [[UIImage alloc] initWithData:imageContent];
        }
    }
    
    return res;
}

+ (NSString*)cacheMediaData:(NSData*)mediaData forURL:(NSString *)mediaURL andType:(NSString *)mimeType {
    NSString* filename = [MediaManager cachePathForMediaURL:mediaURL andType:mimeType];
    
    if ([mediaData writeToFile:filename atomically:YES]) {
        return filename;
    } else {
        return nil;
    }
}

+ (NSString*)cachePathForMediaURL:(NSString*)mediaURL andType:(NSString *)mimeType {
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

// recursive method to compute the folder content size
+ (long long)folderSize:(NSString *)folderPath
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long int folderSize = 0;
    
    while (file = [contentsEnumurator nextObject])
    {
        NSString* itemPath = [folderPath stringByAppendingPathComponent:file];
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:itemPath error:nil];
        
        // is directory
        if ([[fileAttributes objectForKey:NSFileType] isEqual:NSFileTypeDirectory])
        {
            folderSize += [MediaManager folderSize:itemPath];
        }
        else
        {
            folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
        }
    }
    
    return folderSize;
}

+ (NSUInteger)cacheSize {
    
    if (!mediaCachePath) {
        // compute the path
        mediaCachePath = [MediaManager getCachePath];
    }
    
    return (NSUInteger)[MediaManager folderSize:mediaCachePath];
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

@end
