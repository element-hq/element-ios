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

@implementation MediaManager

+ (id)sharedInstance {
    @synchronized(self) {
        if(sharedMediaManager == nil)
            sharedMediaManager = [[self alloc] init];
    }
    return sharedMediaManager;
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
    return [NSString stringWithFormat:@"%@%d.jpg", baseFileName, pictureURL.hash];
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
