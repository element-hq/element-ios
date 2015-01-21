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

#import "ConsoleEmail.h"
#import "MatrixHandler.h"

#import "ConsoleContact.h"

#import "MediaManager.h"

@implementation ConsoleEmail
@synthesize type, emailAddress, contactID, matrixUserID, avatarImage, avatarURL;

- (void) commonInit {
    // init statuses
    gotMatrixID = NO;
    pendingMatrixIDRequest = NO;
    
    // init members
    self.emailAddress = nil;
    self.type = nil;
    self.contactID = nil;
    self.matrixUserID = nil;
    self.avatarURL = @"";
}

- (id)init {
    self = [super init];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithEmailAddress:(NSString*)anEmailAddress andType:(NSString*)aType within:(NSString*)aContactID {
    self = [super init];
    
    if (self) {
        [self commonInit];
        self.emailAddress = anEmailAddress;
        self.type = aType;
        self.contactID = aContactID;
    }
    
    return self;
}

- (void)dealloc {
    // remove the observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)getMatrixID {
    
    // sanity check
    if ((self.emailAddress.length > 0) && (self.contactID.length > 0)) {
        
        // check if the matrix id was not requested
        if (!gotMatrixID && !pendingMatrixIDRequest) {
            MatrixHandler *matrix = [MatrixHandler sharedHandler];
        
            if (matrix.mxRestClient) {
                pendingMatrixIDRequest = YES;
                
                [matrix.mxRestClient lookup3pid:self.emailAddress
                                      forMedium:@"email"
                                        success:^(NSString *userId) {
                                            pendingMatrixIDRequest = NO;
                                            self.matrixUserID = userId;
                                            gotMatrixID = YES;
                                            
                                            if (self.matrixUserID) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kConsoleContactMatrixIdentifierUpdateNotification object:self.contactID userInfo:nil];
                                                });
                                            }
                                        }
                                        failure:^(NSError *error) {
                                            pendingMatrixIDRequest = NO;
                                        }
                 ];
            }
        }
    }
}

- (void)loadAvatarWithSize:(CGSize)avatarSize {
    
    // the avatar image is already done
    if (self.avatarImage) {
        return;
    }
    
    // sanity check
    if (self.matrixUserID) {
        
        // nil -> there is no avatar
        if (!self.avatarURL) {
            return;
        }
        
        // empty string means not yet initialized
        if (self.avatarURL.length > 0) {
            [self downloadAvatarImage];
        } else {
            MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
            
            // check if the user is already known
            MXUser* user = [mxHandler.mxSession userWithUserId:self.matrixUserID];
            
            if (user) {
                self.avatarURL = [mxHandler thumbnailURLForContent:user.avatarUrl inViewSize:avatarSize  withMethod:MXThumbnailingMethodCrop];
                [self downloadAvatarImage];
                
            } else {
                
                if (mxHandler.mxRestClient) {
                    [mxHandler.mxRestClient avatarUrlForUser:self.matrixUserID
                                                  success:^(NSString *avatarUrl) {
                                                      self.avatarURL = [mxHandler thumbnailURLForContent:avatarUrl inViewSize:avatarSize  withMethod:MXThumbnailingMethodCrop];
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
    if (self.avatarImage) {
        return;
    }
    
    if (self.avatarURL.length > 0) {
     
        self.avatarImage = [MediaManager loadCachePictureForURL:self.avatarURL inFolder:kMediaManagerThumbnailFolder];
        
        // the image is already in the cache
        if (self.avatarImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kConsoleContactThumbnailUpdateNotification object:self.contactID userInfo:nil];
            });
        } else  {
            MediaLoader* loader = [MediaManager existingDownloaderForURL:self.avatarURL inFolder:kMediaManagerThumbnailFolder];
            
            if (!loader) {
                loader = [MediaManager downloadMediaFromURL:self.avatarURL withType:@"image/jpeg" inFolder:kMediaManagerThumbnailFolder];
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFinishNotification object:nil];
        }
    }
}

- (void)onMediaDownloadEnd:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        
        if ([url isEqualToString:self.avatarURL]) {
            // update the image
            UIImage* image = [MediaManager loadCachePictureForURL:self.avatarURL inFolder:kMediaManagerThumbnailFolder];
            if (image) {
                self.avatarImage = image;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kConsoleContactThumbnailUpdateNotification object:self.contactID userInfo:nil];
                });
            }
        }
    }
}


@end
