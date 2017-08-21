/*
 Copyright 2017 Aram Sargsyan
 
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

#import "ShareExtensionManager.h"
#import "MXKPieChartHUD.h"
@import MobileCoreServices;

NSString *const kShareExtensionManagerDidChangeMXSessionNotification = @"kShareExtensionManagerDidChangeMXSessionNotification";

typedef NS_ENUM(NSInteger, ImageCompressionMode)
{
    ImageCompressionModeNone,
    ImageCompressionModeSmall,
    ImageCompressionModeMedium,
    ImageCompressionModeLarge
};

@interface ShareExtensionManager ()

// The current user account
@property (nonatomic) MXKAccount *userAccount;

@property ImageCompressionMode imageCompressionMode;
@property CGFloat actualLargeSize;

@end


@implementation ShareExtensionManager

#pragma mark - Lifecycle

+ (instancetype)sharedManager
{
    static ShareExtensionManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[self alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(onMediaUploadProgress:) name:kMXMediaUploadProgressNotification object:nil];
        
        // Add observer to handle logout
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(checkUserAccount) name:kMXKAccountManagerDidRemoveAccountNotification object:nil];
        
        // Add observer on the Extension host
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(checkUserAccount) name:NSExtensionHostWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(suspendSession) name:NSExtensionHostDidEnterBackgroundNotification object:nil];
        
        // Apply the application group
        [MXKAppSettings standardAppSettings].applicationGroup = @"group.im.vector";
    });
    return sharedInstance;
}

- (void)checkUserAccount
{
    // Force account manager to reload account from the local storage.
    [[MXKAccountManager sharedManager] forceReloadAccounts];
    
    if (self.userAccount)
    {
        // Check whether the used account is still the first active one
        MXKAccount *firstAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        
        // Compare the access token
        if (!firstAccount || ![self.userAccount.mxCredentials.accessToken isEqualToString:firstAccount.mxCredentials.accessToken])
        {
            // Remove this account
            [self.userAccount closeSession:YES];
            self.userAccount = nil;
            _mxSession = nil;
            
            // Post notification
            [[NSNotificationCenter defaultCenter] postNotificationName:kShareExtensionManagerDidChangeMXSessionNotification object:_mxSession userInfo:nil];
        }
    }
    
    if (self.userAccount)
    {
        // Resume the matrix session
        [self.userAccount resume];
    }
    else
    {
        // Prepare a new session if a new account is available.
        [self prepareSession];
    }
}

- (void)prepareSession
{    
    // We consider the first enabled account.
    // TODO: Handle multiple accounts
    self.userAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    if (self.userAccount)
    {
        NSLog(@"[ShareExtensionManager] openSession for %@ account", self.userAccount.mxCredentials.userId);
        // Use MXFileStore as MXStore to permanently store events.
        [self.userAccount openSessionWithStore:[[MXFileStore alloc] init]];
        
        _mxSession = self.userAccount.mxSession;
        
        // Post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:kShareExtensionManagerDidChangeMXSessionNotification object:_mxSession userInfo:nil];
    }
}

- (void)suspendSession
{
    [self.userAccount pauseInBackgroundTask];
}

#pragma mark - Public

- (void)setShareExtensionContext:(NSExtensionContext *)shareExtensionContext
{
    _shareExtensionContext = shareExtensionContext;
    
    // Prepare or resume the matrix session.
    [self checkUserAccount];
}

- (void)sendContentToRoom:(MXRoom *)room failureBlock:(void(^)())failureBlock
{
    NSString *UTTypeText = (__bridge NSString *)kUTTypeText;
    NSString *UTTypeURL = (__bridge NSString *)kUTTypeURL;
    NSString *UTTypeImage = (__bridge NSString *)kUTTypeImage;
    NSString *UTTypeVideo = (__bridge NSString *)kUTTypeVideo;
    NSString *UTTypeFileUrl = (__bridge NSString *)kUTTypeFileURL;
    NSString *UTTypeMovie = (__bridge NSString *)kUTTypeMovie;
    
    __weak typeof(self) weakSelf = self;
    
    for (NSExtensionItem *item in self.shareExtensionContext.inputItems)
    {
        for (NSItemProvider *itemProvider in item.attachments)
        {
            if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeFileUrl])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeFileUrl options:nil completionHandler:^(NSURL *fileUrl, NSError * _Null_unspecified error) {
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        [self sendFileWithUrl:fileUrl toRoom:room extensionItem:item failureBlock:failureBlock];
                    }
                }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeText])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeText options:nil completionHandler:^(NSString *text, NSError * _Null_unspecified error) {
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        [self sendText:text toRoom:room extensionItem:item failureBlock:failureBlock];
                    }
                }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeURL])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeURL options:nil completionHandler:^(NSURL *url, NSError * _Null_unspecified error) {
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        [self sendText:url.absoluteString toRoom:room extensionItem:item failureBlock:failureBlock];
                    }
                }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeImage])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeImage options:nil completionHandler:^(NSData *imageData, NSError * _Null_unspecified error)
                 {
                     if (weakSelf)
                     {
                         typeof(self) self = weakSelf;
                         UIImage *image = [[UIImage alloc] initWithData:imageData];
                         UIAlertController *compressionPrompt = [self compressionPromptForImage:image shareBlock:^{
                             [self sendImage:imageData withProvider:itemProvider toRoom:room extensionItem:item failureBlock:failureBlock];
                         }];
                         [self.delegate shareExtensionManager:self showImageCompressionPrompt:compressionPrompt];
                     }
                 }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeVideo])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeVideo options:nil completionHandler:^(NSURL *videoLocalUrl, NSError * _Null_unspecified error)
                 {
                     if (weakSelf)
                     {
                         typeof(self) self = weakSelf;
                         [self sendVideo:videoLocalUrl toRoom:room extensionItem:item failureBlock:failureBlock];
                     }
                 }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeMovie])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeMovie options:nil completionHandler:^(NSURL *videoLocalUrl, NSError * _Null_unspecified error)
                 {
                     if (weakSelf)
                     {
                         typeof(self) self = weakSelf;
                         [self sendVideo:videoLocalUrl toRoom:room extensionItem:item failureBlock:failureBlock];
                     }
                 }];
            }
        }
    }
}

- (BOOL)hasImageTypeContent
{
    for (NSExtensionItem *item in self.shareExtensionContext.inputItems)
    {
        for (NSItemProvider *itemProvider in item.attachments)
        {
            if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeImage])
            {
                return YES;
            }
        }
    }
    return NO;
}

- (void)terminateExtensionCanceled:(BOOL)canceled
{
    [self suspendSession];
    
    if (canceled)
    {
        [self.shareExtensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXUserCancelErrorDomain" code:4201 userInfo:nil]];
    }
    else
    {
        [self.shareExtensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXFailureErrorDomain" code:500 userInfo:nil]];
    }
}

#pragma mark - Private

- (UIAlertController *)compressionPromptForImage:(UIImage *)image shareBlock:(void(^)())shareBlock
{
    UIAlertController *compressionPrompt;
    
    // Get availabe sizes for this image
    MXKImageCompressionSizes compressionSizes = [MXKTools availableCompressionSizesForImage:image];
    
    // Apply the compression mode
    if (compressionSizes.small.fileSize || compressionSizes.medium.fileSize || compressionSizes.large.fileSize)
    {
        __weak typeof(self) weakSelf = self;
        
        compressionPrompt = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"attachment_size_prompt"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        if (compressionSizes.small.fileSize)
        {
            NSString *resolution = [NSString stringWithFormat:@"%@ (%d x %d)", [MXTools fileSizeToString:compressionSizes.small.fileSize round:NO], (int)compressionSizes.small.imageSize.width, (int)compressionSizes.small.imageSize.height];
            
            NSString *title = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"attachment_small"], resolution];
            
            [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    if (weakSelf)
                                                                    {
                                                                        typeof(self) self = weakSelf;
                                                                        
                                                                        // Send the small image
                                                                        self.imageCompressionMode = ImageCompressionModeSmall;
                                                                        if (shareBlock)
                                                                        {
                                                                            shareBlock();
                                                                        }
                                                                        
                                                                        [compressionPrompt dismissViewControllerAnimated:YES completion:nil];
                                                                    }
                                                                    
                                                                }]];
        }
        
        if (compressionSizes.medium.fileSize)
        {
            NSString *resolution = [NSString stringWithFormat:@"%@ (%d x %d)", [MXTools fileSizeToString:compressionSizes.medium.fileSize round:NO], (int)compressionSizes.medium.imageSize.width, (int)compressionSizes.medium.imageSize.height];
            
            NSString *title = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"attachment_medium"], resolution];
            
            [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    if (weakSelf)
                                                                    {
                                                                        typeof(self) self = weakSelf;
                                                                        
                                                                        // Send the medium image
                                                                        self.imageCompressionMode = ImageCompressionModeMedium;
                                                                        if (shareBlock)
                                                                        {
                                                                            shareBlock();
                                                                        }
                                                                        
                                                                        [compressionPrompt dismissViewControllerAnimated:YES completion:nil];
                                                                    }
                                                                    
                                                                }]];
        }
        
        if (compressionSizes.large.fileSize)
        {
            NSString *resolution = [NSString stringWithFormat:@"%@ (%d x %d)", [MXTools fileSizeToString:compressionSizes.large.fileSize round:NO], (int)compressionSizes.large.imageSize.width, (int)compressionSizes.large.imageSize.height];
            
            NSString *title = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"attachment_large"], resolution];
            
            [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    if (weakSelf)
                                                                    {
                                                                        typeof(self) self = weakSelf;
                                                                        
                                                                        // Send the large image
                                                                        self.imageCompressionMode = ImageCompressionModeLarge;
                                                                        self.actualLargeSize = compressionSizes.actualLargeSize;
                                                                        if (shareBlock)
                                                                        {
                                                                            shareBlock();
                                                                        }
                                                                        
                                                                        [compressionPrompt dismissViewControllerAnimated:YES completion:nil];
                                                                    }
                                                                    
                                                                }]];
        }
        
        NSString *resolution = [NSString stringWithFormat:@"%@ (%d x %d)", [MXTools fileSizeToString:compressionSizes.original.fileSize round:NO], (int)compressionSizes.original.imageSize.width, (int)compressionSizes.original.imageSize.height];
        
        NSString *title = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"attachment_original"], resolution];
        
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                if (weakSelf)
                                                                {
                                                                    typeof(self) self = weakSelf;
                                                                    
                                                                    self.imageCompressionMode = ImageCompressionModeNone;
                                                                    if (shareBlock)
                                                                    {
                                                                        shareBlock();
                                                                    }
                                                                    
                                                                    [compressionPrompt dismissViewControllerAnimated:YES completion:nil];
                                                                }
                                                                
                                                            }]];
        
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                if (weakSelf)
                                                                {
                                                                    [compressionPrompt dismissViewControllerAnimated:YES completion:nil];
                                                                }
                                                                
                                                            }]];
        
        
    }
    
    return compressionPrompt;
}

- (void)didStartSendingToRoom:(MXRoom *)room
{
    if ([self.delegate respondsToSelector:@selector(shareExtensionManager:didStartSendingContentToRoom:)])
    {
        [self.delegate shareExtensionManager:self didStartSendingContentToRoom:room];
    }
}

#pragma mark - Notifications

- (void)onMediaUploadProgress:(NSNotification *)notification
{
    if ([self.delegate respondsToSelector:@selector(shareExtensionManager:mediaUploadProgress:)])
    {
        [self.delegate shareExtensionManager:self mediaUploadProgress:((NSNumber *)notification.userInfo[kMXMediaLoaderProgressValueKey]).floatValue];
    }
}

#pragma mark - Sharing

- (void)sendText:(NSString *)text toRoom:(MXRoom *)room extensionItem:(NSExtensionItem *)extensionItem failureBlock:(void(^)())failureBlock
{
    [self didStartSendingToRoom:room];
    if (!text)
    {
        NSLog(@"[ShareExtensionManager] loadItemForTypeIdentifier: failed.");
        if (failureBlock)
        {
            failureBlock();
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [room sendTextMessage:text success:^(NSString *eventId) {
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            [self suspendSession];
            [self.shareExtensionContext completeRequestReturningItems:@[extensionItem] completionHandler:nil];
        }
    } failure:^(NSError *error) {
        NSLog(@"[ShareExtensionManager] sendTextMessage failed.");
        if (failureBlock)
        {
            failureBlock();
        }
    }];
}

- (void)sendFileWithUrl:(NSURL *)fileUrl toRoom:(MXRoom *)room extensionItem:(NSExtensionItem *)extensionItem failureBlock:(void(^)())failureBlock
{
    [self didStartSendingToRoom:room];
    if (!fileUrl)
    {
        NSLog(@"[ShareExtensionManager] loadItemForTypeIdentifier: failed.");
        if (failureBlock)
        {
            failureBlock();
        }
        return;
    }
    NSString *mimeType = [fileUrl pathExtension];
    
    __weak typeof(self) weakSelf = self;
    
    [room sendFile:fileUrl mimeType:mimeType localEcho:nil success:^(NSString *eventId) {
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            [self suspendSession];
            [self.shareExtensionContext completeRequestReturningItems:@[extensionItem] completionHandler:nil];
        }
    } failure:^(NSError *error) {
        NSLog(@"[ShareExtensionManager] sendFile failed.");
        if (failureBlock)
        {
            failureBlock();
        }
    } keepActualFilename:YES];
}

- (void)sendImage:(NSData *)imageData withProvider:(NSItemProvider*)itemProvider toRoom:(MXRoom *)room extensionItem:(NSExtensionItem *)extensionItem failureBlock:(void(^)())failureBlock
{
    [self didStartSendingToRoom:room];
    if (!imageData)
    {
        NSLog(@"[ShareExtensionManager] loadItemForTypeIdentifier: failed.");
        if (failureBlock)
        {
            failureBlock();
        }
        return;
    }
    
    // Prepare the image
    BOOL rotated = NO;
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    
    // Make sure the uploaded image orientation is up
    if (image.imageOrientation != UIImageOrientationUp)
    {
        image = [MXKTools forceImageOrientationUp:image];
        rotated = YES;
    }
    
    if (self.imageCompressionMode == ImageCompressionModeSmall)
    {
        image = [MXKTools reduceImage:image toFitInSize:CGSizeMake(MXKTOOLS_SMALL_IMAGE_SIZE, MXKTOOLS_SMALL_IMAGE_SIZE)];
    }
    else if (self.imageCompressionMode == ImageCompressionModeMedium)
    {
        image = [MXKTools reduceImage:image toFitInSize:CGSizeMake(MXKTOOLS_MEDIUM_IMAGE_SIZE, MXKTOOLS_MEDIUM_IMAGE_SIZE)];
    }
    else if (self.imageCompressionMode == ImageCompressionModeLarge)
    {
        image = [MXKTools reduceImage:image toFitInSize:CGSizeMake(self.actualLargeSize, self.actualLargeSize)];
    }
    
    NSString *mimeType;
    if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePNG])
    {
        mimeType = @"image/png";
        
        if (rotated)
        {
            // Update imageData
            imageData = UIImagePNGRepresentation(image);
        }
    }
    else if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeJPEG])
    {
        mimeType = @"image/jpeg";
        
        if (rotated)
        {
            // Update imageData
            imageData = UIImageJPEGRepresentation(image, 1.0);
        }
    }
    else
    {
        imageData = UIImageJPEGRepresentation(image, 1.0);
        image = [[UIImage alloc] initWithData:imageData];
        mimeType = @"image/jpeg";
    }
    
    UIImage *thumbnail = nil;
    // Thumbnail is useful only in case of encrypted room
    if (room.state.isEncrypted)
    {
        thumbnail = [MXKTools reduceImage:image toFitInSize:CGSizeMake(800, 600)];
        if (thumbnail == image)
        {
            thumbnail = nil;
        }
    }
    
    __weak typeof(self) weakSelf = self;
    
    [room sendImage:imageData withImageSize:image.size mimeType:mimeType andThumbnail:thumbnail localEcho:nil success:^(NSString *eventId) {
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            [self suspendSession];
            [self.shareExtensionContext completeRequestReturningItems:@[extensionItem] completionHandler:nil];
        }
    } failure:^(NSError *error) {
        NSLog(@"[ShareExtensionManager] sendImage failed.");
        if (failureBlock)
        {
            failureBlock();
        }
    }];
}

- (void)sendVideo:(NSURL *)videoLocalUrl toRoom:(MXRoom *)room extensionItem:(NSExtensionItem *)extensionItem failureBlock:(void(^)())failureBlock
{
    [self didStartSendingToRoom:room];
    if (!videoLocalUrl)
    {
        NSLog(@"[ShareExtensionManager] loadItemForTypeIdentifier: failed.");
        if (failureBlock)
        {
            failureBlock();
        }
        return;
    }
    
    // Retrieve the video frame at 1 sec to define the video thumbnail
    AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:videoLocalUrl options:nil];
    AVAssetImageGenerator *assetImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMake(1, 1);
    CGImageRef imageRef = [assetImageGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
    // Finalize video attachment
    UIImage *videoThumbnail = [[UIImage alloc] initWithCGImage:imageRef];
    CFRelease(imageRef);
    
    __weak typeof(self) weakSelf = self;
    
    [room sendVideo:videoLocalUrl withThumbnail:videoThumbnail localEcho:nil success:^(NSString *eventId) {
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            [self suspendSession];
            [self.shareExtensionContext completeRequestReturningItems:@[extensionItem] completionHandler:nil];
        }
    } failure:^(NSError *error) {
        NSLog(@"[ShareExtensionManager] sendVideo failed.");
        if (failureBlock)
        {
            failureBlock();
        }
    }];
}


@end
