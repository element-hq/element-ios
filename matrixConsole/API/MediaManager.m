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

#import "AppSettings.h"
#import "ConsoleTools.h"

#import "AppDelegate.h"

NSString *const kMediaManagerPrefixForDummyURL = @"dummyUrl-";

NSString *const kMediaDownloadDidFinishNotification = @"kMediaDownloadDidFinishNotification";
NSString *const kMediaDownloadDidFailNotification = @"kMediaDownloadDidFailNotification";

NSString *const kMediaManagerThumbnailFolder = @"kMediaManagerThumbnailFolder";

static NSString* mediaCachePath  = nil;
static NSString *mediaDir        = @"mediacache";

static MediaManager *sharedMediaManager = nil;

// store the current cache size
// avoid listing files because it is useless
static NSUInteger storageCacheSize = 0;

@implementation MediaManager

// Table of downloads in progress
static NSMutableDictionary* downloadTableByURL = nil;
// Table of uploads in progress
static NSMutableDictionary* uploadTableById = nil;

#pragma mark - Media Download

+ (NSString*)downloadKey:mediaURL andFolder:(NSString*)folder {
    NSMutableString* key = [[NSMutableString alloc] init];
    
    [key appendString:mediaURL];
    
    if (folder.length > 0) {
        [key appendFormat:@"_download_%@", folder];
    }
    return key;
}

+ (MediaLoader*)downloadMediaFromURL:(NSString*)mediaURL withType:(NSString *)mimeType inFolder:(NSString*)folder {
    if (mediaURL && [mediaURL hasPrefix:kMediaManagerPrefixForDummyURL] == NO) {
        // Create a media loader to download data
        MediaLoader *mediaLoader = [[MediaLoader alloc] init];
        // Report this loader
        if (!downloadTableByURL) {
            downloadTableByURL = [[NSMutableDictionary alloc] init];
        }
        [downloadTableByURL setValue:mediaLoader forKey:[MediaManager downloadKey:mediaURL andFolder:folder]];
        
        // Launch download
        [mediaLoader downloadMedia:mediaURL mimeType:mimeType folder:folder success:^(NSString *cacheFilePath) {
            [downloadTableByURL removeObjectForKey:[MediaManager downloadKey:mediaURL andFolder:folder]];
            [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFinishNotification object:mediaURL userInfo:nil];
        } failure:^(NSError *error) {
            [downloadTableByURL removeObjectForKey:[MediaManager downloadKey:mediaURL andFolder:folder]];
            NSLog(@"Failed to download image (%@): %@", mediaURL, error);
            [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:mediaURL userInfo:nil];
        }];
        return mediaLoader;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kMediaDownloadDidFailNotification object:mediaURL userInfo:nil];
    return nil;
}

// try to find out a media loader from a media URL
+ (id)existingDownloaderForURL:(NSString*)url inFolder:(NSString*)folder {
    if (downloadTableByURL && url) {
        return [downloadTableByURL valueForKey:[MediaManager downloadKey:url andFolder:folder]];
    }
    return nil;
}

+ (void)cancelDownloadsInFolder:(NSString*)folder {
    NSMutableArray* pendingLoaders =[[NSMutableArray alloc] init];
    NSArray* allKeys = [downloadTableByURL allKeys];
    
    // any folder name ?
    if (folder.length > 0) {
        
        NSString* keySuffix = [NSString stringWithFormat:@"_download_%@", folder];
        
        for(NSString* key in allKeys) {
            if ([key hasSuffix:keySuffix]) {
                [pendingLoaders addObject:[downloadTableByURL valueForKey:key]];
                [downloadTableByURL removeObjectForKey:key];
            }
        }
    } else {
        for(NSString* key in allKeys) {
            if ([key rangeOfString:@"_download_"].location == NSNotFound) {
                [pendingLoaders addObject:[downloadTableByURL valueForKey:key]];
                [downloadTableByURL removeObjectForKey:key];
            }
        }
    }
    
    if (pendingLoaders > 0) {
        for (MediaLoader* loader in pendingLoaders) {
            [loader cancel];
        }
    }
}

// cancel any pending download
+ (void)cancelDownloads {
    NSArray* allKeys = [downloadTableByURL allKeys];
    
    for(NSString* key in allKeys) {
        [[downloadTableByURL valueForKey:key] cancel];
        [downloadTableByURL removeObjectForKey:key];
    }
}

#pragma mark - Media Uploader

+ (NSString*)uploadKey:uploadId andFolder:(NSString*)folder {
    NSMutableString* key = [[NSMutableString alloc] init];
    
    [key appendString:uploadId];
    
    if (folder.length > 0) {
        [key appendFormat:@"_upload_%@", folder];
    }
    return key;
}

+ (MediaLoader*)prepareUploaderWithId:(NSString *)uploadId initialRange:(CGFloat)initialRange andRange:(CGFloat)range inFolder:(NSString*)aFolder {
    if (uploadId) {
        // Create a media loader to upload data
        MediaLoader *mediaLoader = [[MediaLoader alloc] initWithUploadId:uploadId initialRange:initialRange andRange:range folder:aFolder];
        // Report this loader
        if (!uploadTableById) {
            uploadTableById =  [[NSMutableDictionary alloc] init];
        }
        [uploadTableById setValue:mediaLoader forKey:[MediaManager uploadKey:uploadId andFolder:aFolder]];
        return mediaLoader;
    }
    return nil;
}

+ (MediaLoader*)existingUploaderWithId:(NSString*)uploadId inFolder:(NSString*)folder {
    if (uploadTableById && uploadId) {
        return [uploadTableById valueForKey:[MediaManager uploadKey:uploadId andFolder:folder]];
    }
    return nil;
}

+ (void)removeUploaderWithId:(NSString*)uploadId inFolder:(NSString*)folder {
    if (uploadTableById && uploadId) {
        return [uploadTableById removeObjectForKey:[MediaManager uploadKey:uploadId andFolder:folder]];
    }
}

+ (void)cancelUploadsInFolder:(NSString*)folder {
    NSMutableArray* pendingLoaders =[[NSMutableArray alloc] init];
    NSArray* allKeys = [uploadTableById allKeys];
    
    //
    if (folder.length > 0) {
        
        NSString* keySuffix = [NSString stringWithFormat:@"_upload_%@", folder];
        
        for(NSString* key in allKeys) {
            if ([key hasSuffix:keySuffix]) {
                [pendingLoaders addObject:[uploadTableById valueForKey:key]];
                [uploadTableById removeObjectForKey:key];
            }
        }
    } else {
        for(NSString* key in allKeys) {
            if ([key rangeOfString:@"_upload_"].location == NSNotFound) {
                [pendingLoaders addObject:[uploadTableById valueForKey:key]];
                [uploadTableById removeObjectForKey:key];
            }
        }
    }
    
    if (pendingLoaders > 0) {
        for (MediaLoader* loader in pendingLoaders) {
            [loader cancel];
        }
    }
}

// cancel any pending download
+ (void)cancelUploads {
    NSArray* allKeys = [uploadTableById allKeys];
    
    for(NSString* key in allKeys) {
        [[uploadTableById valueForKey:key] cancel];
        [uploadTableById removeObjectForKey:key];
    }
}

#pragma mark - Cache Handling

+ (UIImage*)loadCachePictureForURL:(NSString*)pictureURL inFolder:(NSString*)folder {
    UIImage* res = nil;
    NSString* filename = [MediaManager cachePathForMediaURL:pictureURL andType:@"image/jpeg" inFolder:folder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
        NSData* imageContent = [NSData dataWithContentsOfFile:filename options:(NSDataReadingMappedAlways | NSDataReadingUncached) error:nil];
        if (imageContent) {
            res = [[UIImage alloc] initWithData:imageContent];
        }
    }
    
    return res;
}

+ (void)reduceCacheSizeToInsert:(NSUInteger)bytes {
    
    if (([MediaManager cacheSize] + bytes) > [MediaManager maxAllowedCacheSize]) {
        
        NSString* thumbnailPath = [MediaManager cacheFolderPath:kMediaManagerThumbnailFolder];
        NSString* activeRoomPath = nil;
        
        if ([AppDelegate theDelegate].masterTabBarController.visibleRoomId) {
            activeRoomPath = [MediaManager cacheFolderPath:[AppDelegate theDelegate].masterTabBarController.visibleRoomId];
        }
        
        // add a 50 MB margin to reduce this method call
        NSUInteger maxSize = 0;
        
        // check if the cache cannot content the file
        if ([MediaManager maxAllowedCacheSize] < (bytes - 50 * 1024 * 1024)) {
            // delete item as much as possible
            maxSize = 0;
        } else {
            maxSize = [MediaManager maxAllowedCacheSize] - bytes - 50 * 1024 * 1024;
        }
        
        NSArray* filesList = [ConsoleTools listFiles:mediaCachePath timeSorted:YES largeFilesFirst:YES];
        
        // list the files sorted by timestamp
        for(NSString* filepath in filesList) {
            // do not release the contact thumbnails : they must be released by when the contacts are deleted
            // do not release the active room medias : it could trigger weird UI effect on a tablet / iphone 6+
            if (![filepath hasPrefix:thumbnailPath] && (!activeRoomPath || ![filepath hasPrefix:activeRoomPath])) {
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filepath error:nil];
                
                // sanity check
                if (fileAttributes) {
                    // delete the files
                    if ([[NSFileManager defaultManager] removeItemAtPath:filepath error:nil]) {
                        storageCacheSize -= fileAttributes.fileSize;
                    
                        if (storageCacheSize < maxSize) {
                            return;
                        }
                    }
                }
            }
        }
    }
}

+ (NSString*)cacheMediaData:(NSData*)mediaData forURL:(NSString *)mediaURL andType:(NSString *)mimeType inFolder:(NSString*)folder {
    [MediaManager reduceCacheSizeToInsert:mediaData.length];
    
    NSString* filename = [MediaManager cachePathForMediaURL:mediaURL andType:mimeType inFolder:folder];
    
    if ([mediaData writeToFile:filename atomically:YES]) {
        storageCacheSize += mediaData.length;
        return filename;
    } else {
        return nil;
    }
}

+ (NSString*)cacheFolderPath:(NSString*)folder {
    NSString* path = [MediaManager getCachePath];
    
    // update the path if the folder is provided
    if (folder.length > 0) {
        path = [[MediaManager getCachePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu", (unsigned long)folder.hash]];
    }
    
    // create the folder it does not exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    return path;
}

+ (NSString*)cachePathForMediaURL:(NSString*)mediaURL andType:(NSString *)mimeType inFolder:(NSString*)folder {
    NSString* fileExt = [ConsoleTools fileExtensionFromContentType:mimeType];
    NSString* fileBase = @"";
    
    // use the mime type to extract a base filename
    if ([mimeType rangeOfString:@"/"].location != NSNotFound){
        NSArray *components = [mimeType componentsSeparatedByString:@"/"];
        fileBase = [components objectAtIndex:0];
    }
    
    return [[MediaManager cacheFolderPath:folder] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%lu%@", [fileBase substringToIndex:3], (unsigned long)mediaURL.hash, fileExt]];
}

+ (NSUInteger)cacheSize {
    
    if (!mediaCachePath) {
        // compute the path
        mediaCachePath = [MediaManager getCachePath];
    }
    
    // assume that 0 means uninitialized
    if (storageCacheSize == 0) {
        storageCacheSize = (NSUInteger)[ConsoleTools folderSize:mediaCachePath];
    }
        
    return storageCacheSize;
}

+ (NSUInteger)minCacheSize {
    NSUInteger minSize = [MediaManager cacheSize];
    NSArray* filenamesList = [ConsoleTools listFiles:mediaCachePath timeSorted:NO largeFilesFirst:YES];
 
    NSFileManager* defaultManager = [NSFileManager defaultManager];
    
    for(NSString* filename in filenamesList) {
        NSDictionary* attsDict = [defaultManager attributesOfItemAtPath:filename error:nil];
        
        if (attsDict) {
            if (attsDict.fileSize > 100 * 1024) {
                minSize -= attsDict.fileSize;
            }
        }
    }
    return minSize;
}

+ (NSUInteger)currentMaxCacheSize {
    return [AppSettings sharedSettings].currentMaxMediaCacheSize;
}

+ (void)setCurrentMaxCacheSize:(NSUInteger)maxCacheSize {
    [AppSettings sharedSettings].currentMaxMediaCacheSize = maxCacheSize;
}

+ (NSUInteger)maxAllowedCacheSize {
    return [AppSettings sharedSettings].maxAllowedMediaCacheSize;
}

+ (void)clearCache {
    NSError *error = nil;
    
    if (!mediaCachePath) {
        // compute the path
        mediaCachePath = [MediaManager getCachePath];
    }
    
    [MediaManager cancelDownloads];
    [MediaManager cancelUploads];
    
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
