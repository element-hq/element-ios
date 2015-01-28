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

#import "MXCContactField.h"

// wanr when there is a contact update
#import "MXCContact.h"

// image URL
#import "MatrixSDKHandler.h"

// get the thumbnail
#import "MediaManager.h"


@interface MXCContactField() {
    NSString* avatarURL;
}
@end

@implementation MXCContactField

- (void)initFields {
    // init members
    _contactID = nil;
    _matrixID = nil;
    avatarURL = @"";
}

- (id)initWithContactID:(NSString*)contactID matrixID:(NSString*)matrixID {
    self = [super init];
    
    if (self) {
        [self initFields];
        _contactID = contactID;
        _matrixID = matrixID;
    }
    
    return self;
}
- (void)dealloc {
    // remove the observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setMatrixID:(NSString*)aMatrixID {
    // check if there is an update
    // nil test + string comparison
    if ((aMatrixID != _matrixID) && ![aMatrixID isEqualToString:_matrixID]) {
        _matrixID = aMatrixID;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXCContactMatrixIdentifierUpdateNotification object:_contactID userInfo:nil];
        });
    }
}

- (void)loadAvatarWithSize:(CGSize)avatarSize {
    
    // the avatar image is already done
    if (_avatarImage) {
        return;
    }
    
    // sanity check
    if (_matrixID) {
        
        // nil -> there is no avatar
        if (!avatarURL) {
            return;
        }
        
        // empty string means not yet initialized
        if (avatarURL.length > 0) {
            [self downloadAvatarImage];
        } else {
            MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
            
            // check if the user is already known
            MXUser* user = [mxHandler.mxSession userWithUserId:_matrixID];
            
            if (user) {
                avatarURL = [mxHandler thumbnailURLForContent:user.avatarUrl inViewSize:avatarSize  withMethod:MXThumbnailingMethodCrop];
                [self downloadAvatarImage];
                
            } else {
                
                if (mxHandler.mxRestClient) {
                    [mxHandler.mxRestClient avatarUrlForUser:_matrixID
                                                     success:^(NSString *avatarUrl) {
                                                         avatarURL = [mxHandler thumbnailURLForContent:avatarUrl inViewSize:avatarSize  withMethod:MXThumbnailingMethodCrop];
                                                         [self downloadAvatarImage];
                                                     }
                                                     failure:^(NSError *error) {
                                                         //
                                                     }];
                }
            }
        }
    }
}

- (void)downloadAvatarImage {
    
    // the avatar image is already done
    if (_avatarImage) {
        return;
    }
    
    if (avatarURL.length > 0) {
        
        _avatarImage = [MediaManager loadCachePictureForURL:avatarURL inFolder:kMediaManagerThumbnailFolder];
        
        // the image is already in the cache
        if (_avatarImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXCContactThumbnailUpdateNotification object:_contactID userInfo:nil];
            });
        } else  {
            MediaLoader* loader = [MediaManager existingDownloaderForURL:avatarURL inFolder:kMediaManagerThumbnailFolder];
            
            if (!loader) {
                loader = [MediaManager downloadMediaFromURL:avatarURL withType:@"image/jpeg" inFolder:kMediaManagerThumbnailFolder];
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFinishNotification object:nil];
        }
    }
}

- (void)onMediaDownloadEnd:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        
        if ([url isEqualToString:avatarURL]) {
            // update the image
            UIImage* image = [MediaManager loadCachePictureForURL:avatarURL inFolder:kMediaManagerThumbnailFolder];
            if (image) {
                _avatarImage = image;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXCContactThumbnailUpdateNotification object:_contactID userInfo:nil];
                });
            }
        }
    }
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    if (self) {
        [self initFields];
        _contactID = [coder decodeObjectForKey:@"contactID"];
        _matrixID = [coder decodeObjectForKey:@"matrixID"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_contactID forKey:@"contactID"];
    [coder encodeObject:_matrixID forKey:@"matrixID"];
}

@end
