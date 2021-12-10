/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
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

#import "MXKContactField.h"

@import MatrixSDK.MXMediaManager;

#import "MXKContactManager.h"

@interface MXKContactField()
{
    // Tell whether we already check the contact avatar definition.
    BOOL shouldCheckAvatarURL;
    // The media manager of the session used to retrieve the contect avatar url
    // This manager is used to download this avatar if need
    MXMediaManager *mediaManager;
    // The current download id
    NSString *downloadId;
}
@end

@implementation MXKContactField

- (void)initFields
{
    // init members
    _contactID = nil;
    _matrixID = nil;
    
    [self resetMatrixAvatar];
}

- (id)initWithContactID:(NSString*)contactID matrixID:(NSString*)matrixID
{
    self = [super init];
    
    if (self)
    {
        [self initFields];
        _contactID = contactID;
        _matrixID = matrixID;
    }
    
    return self;
}

- (void)resetMatrixAvatar
{
    _avatarImage = nil;
    _matrixAvatarURL = nil;
    shouldCheckAvatarURL = YES;
    mediaManager = nil;
    downloadId = nil;
}

- (void)loadAvatarWithSize:(CGSize)avatarSize
{
    // Check whether the avatar image is already set
    if (_avatarImage)
    {
        return;
    }
    
    // Sanity check
    if (_matrixID)
    {
        if (shouldCheckAvatarURL)
        {
            // Consider here all sessions reported into contact manager
            NSArray* mxSessions = [MXKContactManager sharedManager].mxSessions;
            
            if (mxSessions.count)
            {
                // Check whether a matrix user is already known
                MXUser* user;
                MXSession *mxSession;
                
                for (mxSession in mxSessions)
                {
                    user = [mxSession userWithUserId:_matrixID];
                    if (user)
                    {
                        _matrixAvatarURL = user.avatarUrl;
                        if (_matrixAvatarURL)
                        {
                            shouldCheckAvatarURL = NO;
                            mediaManager = mxSession.mediaManager;
                            [self downloadAvatarImage:avatarSize];
                        }
                        break;
                    }
                }
                
                // Trigger a server request if this url has not been found.
                if (shouldCheckAvatarURL)
                {
                    MXWeakify(self);
                    [mxSession.matrixRestClient avatarUrlForUser:_matrixID
                                                         success:^(NSString *mxAvatarUrl) {
                                                             
                                                             MXStrongifyAndReturnIfNil(self);
                                                             self.matrixAvatarURL = mxAvatarUrl;
                                                             self->shouldCheckAvatarURL = NO;
                                                             self->mediaManager = mxSession.mediaManager;
                                                             [self downloadAvatarImage:avatarSize];
                                                             
                                                         } failure:nil];
                }
            }
        }
        else if (_matrixAvatarURL)
        {
            [self downloadAvatarImage:avatarSize];
        }
        // Do nothing if the avatar url has been checked, and it is null.
    }
}

- (void)downloadAvatarImage:(CGSize)avatarSize
{
    // the avatar image is already done
    if (_avatarImage)
    {
        return;
    }
    
    if (_matrixAvatarURL)
    {
        NSString *cacheFilePath = [MXMediaManager thumbnailCachePathForMatrixContentURI:_matrixAvatarURL
                                                                                andType:nil
                                                                               inFolder:kMXMediaManagerAvatarThumbnailFolder
                                                                          toFitViewSize:avatarSize
                                                                             withMethod:MXThumbnailingMethodCrop];
        _avatarImage = [MXMediaManager loadPictureFromFilePath:cacheFilePath];
        
        // the image is already in the cache
        if (_avatarImage)
        {
            MXWeakify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                MXStrongifyAndReturnIfNil(self);
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactThumbnailUpdateNotification object:self.contactID userInfo:nil];
            });
        }
        else
        {
            NSString *downloadId = [MXMediaManager thumbnailDownloadIdForMatrixContentURI:_matrixAvatarURL inFolder:kMXMediaManagerAvatarThumbnailFolder toFitViewSize:avatarSize withMethod:MXThumbnailingMethodCrop];
            MXMediaLoader* loader = [MXMediaManager existingDownloaderWithIdentifier:downloadId];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXMediaLoaderStateDidChangeNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMXMediaLoaderStateDidChangeNotification object:loader];
            if (!loader && mediaManager)
            {
                [mediaManager downloadThumbnailFromMatrixContentURI:_matrixAvatarURL
                                                                     withType:nil
                                                                     inFolder:kMXMediaManagerAvatarThumbnailFolder
                                                                toFitViewSize:avatarSize
                                                                   withMethod:MXThumbnailingMethodCrop
                                                                      success:nil
                                                                      failure:nil];
            }
        }
    }
}

- (void)onMediaDownloadEnd:(NSNotification *)notif
{
    MXMediaLoader *loader = (MXMediaLoader*)notif.object;
    if ([loader.downloadId isEqualToString:downloadId])
    {
        // update the image
        switch (loader.state) {
            case MXMediaLoaderStateDownloadCompleted:
            {
                UIImage *image = [MXMediaManager loadPictureFromFilePath:loader.downloadOutputFilePath];
                if (image)
                {
                    _avatarImage = image;
                    
                    MXWeakify(self);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        MXStrongifyAndReturnIfNil(self);
                        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactThumbnailUpdateNotification object:self.contactID userInfo:nil];
                    });
                }
                [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXMediaLoaderStateDidChangeNotification object:nil];
                downloadId = nil;
                break;
            }
            case MXMediaLoaderStateDownloadFailed:
            case MXMediaLoaderStateCancelled:
                [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXMediaLoaderStateDidChangeNotification object:nil];
                downloadId = nil;
                break;
            default:
                break;
        }
    }
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    if (self)
    {
        [self initFields];
        _contactID = [coder decodeObjectForKey:@"contactID"];
        _matrixID = [coder decodeObjectForKey:@"matrixID"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_contactID forKey:@"contactID"];
    [coder encodeObject:_matrixID forKey:@"matrixID"];
}

@end
