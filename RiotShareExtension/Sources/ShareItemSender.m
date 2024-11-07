// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@import MobileCoreServices;

#import "ShareItemSender.h"

#import "GeneratedInterface-Swift.h"

static const CGFloat kLargeImageSizeMaxDimension = 2048.0;
static const CGSize kThumbnailSize = {800.0, 600.0};
/// A safe maximum file size for an image to send the original.
static const NSUInteger kImageMaxFileSize = 20 * 1024 * 1024;

typedef NS_ENUM(NSInteger, ImageCompressionMode)
{
    ImageCompressionModeNone,
    ImageCompressionModeSmall,
    ImageCompressionModeMedium,
    ImageCompressionModeLarge
};

@interface ShareItemSender ()

@property (nonatomic, weak, readonly) UIViewController *rootViewController;
@property (nonatomic, strong, readonly) ShareExtensionShareItemProvider *shareItemProvider;

@property (nonatomic, strong, readonly) NSMutableArray<NSData *> *pendingImages;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSNumber *> *imageUploadProgresses;

@property (nonatomic, assign) ImageCompressionMode imageCompressionMode;
@property (nonatomic, assign) CGFloat actualLargeSize;

@end

@implementation ShareItemSender
@synthesize delegate;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
                         shareItemProvider:(ShareExtensionShareItemProvider *)shareItemProvider
{
    if (self = [super init]) {
        _rootViewController = rootViewController;
        _shareItemProvider = shareItemProvider;
        
        _pendingImages = [NSMutableArray array];
        _imageUploadProgresses = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaLoaderStateDidChange:) name:kMXMediaLoaderStateDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)didStartSending
{
    [self.delegate shareItemSenderDidStartSending:self];
}

- (void)presentCompressionPrompt:(UIAlertController *)compressionPrompt
{
    [compressionPrompt popoverPresentationController].sourceView = self.rootViewController.view;
    [compressionPrompt popoverPresentationController].sourceRect = self.rootViewController.view.frame;
    [self.rootViewController.presentedViewController presentViewController:compressionPrompt animated:YES completion:nil];
}

- (BOOL)roomsContainEncryptedRoom:(NSArray<MXRoom *> *)rooms
{
    BOOL foundEncryptedRoom = NO;
    
    for (MXRoom *room in rooms)
    {
        if (room.summary.isEncrypted)
        {
            foundEncryptedRoom = YES;
            break;
        }
    }
    
    return foundEncryptedRoom;
}

- (void)resetPendingData
{
    [self.pendingImages removeAllObjects];
    [self.imageUploadProgresses removeAllObjects];
}

- (void)sendItemsToRooms:(NSArray<MXRoom *> *)rooms success:(void (^)(void))success failure:(void (^)(NSArray<NSError *> *))failure
{
    [self resetPendingData];
    
    __block NSMutableArray<NSError *> *errors;
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    void (^requestSuccess)(void) = ^() {
        dispatch_group_leave(dispatchGroup);
    };
    
    void (^requestFailure)(NSError *) = ^(NSError *requestError) {
        if (errors == nil)
        {
            errors = [NSMutableArray array];
        }
        
        if(requestError)
        {
            [errors addObject:requestError];
        }
        
        dispatch_group_leave(dispatchGroup);
    };
    
    MXWeakify(self);
    for (id<ShareItemProtocol> item in self.shareItemProvider.items)
    {
        if (item.type == ShareItemTypeText || item.type == ShareItemTypeURL) {
            dispatch_group_enter(dispatchGroup);
            [self.shareItemProvider loadItem:item completion:^(id item, NSError *error) {
                MXStrongifyAndReturnIfNil(self);
                
                if (error)
                {
                    requestFailure(error);
                    return;
                }
                
                NSString *text = nil;
                if([item isKindOfClass:[NSString class]])
                {
                    text = item;
                }
                else if([item isKindOfClass:[NSURL class]])
                {
                    text = [(NSURL *)item absoluteString];
                }
                
                if(text.length == 0)
                {
                    requestFailure(nil);
                    return;
                }
                
                [self sendText:text toRooms:rooms success:requestSuccess failure:requestFailure];
            }];
        }
        
        if (item.type == ShareItemTypeFileURL) {
            dispatch_group_enter(dispatchGroup);
            [self.shareItemProvider loadItem:item completion:^(NSURL *url, NSError *error) {
                MXStrongifyAndReturnIfNil(self);
                
                if (error)
                {
                    requestFailure(error);
                    return;
                }
                
                [self sendFileWithUrl:url toRooms:rooms success:requestSuccess failure:requestFailure];
            }];
        }
        
        if (item.type == ShareItemTypeVideo || item.type == ShareItemTypeMovie)
        {
            dispatch_group_enter(dispatchGroup);
            [self.shareItemProvider loadItem:item completion:^(NSURL *videoLocalUrl, NSError *error) {
                MXStrongifyAndReturnIfNil(self);
                
                if (error)
                {
                    requestFailure(error);
                    return;
                }
                
                [self sendVideo:videoLocalUrl toRooms:rooms success:requestSuccess failure:requestFailure];
            }];
        }
        
        if (item.type == ShareItemTypeImage)
        {
            dispatch_group_enter(dispatchGroup);
            [self.shareItemProvider loadItem:item completion:^(id<NSSecureCoding> itemProviderItem, NSError *error) {
                MXStrongifyAndReturnIfNil(self);
                
                if (error)
                {
                    requestFailure(error);
                    return;
                }
                
                NSData *imageData;
                if ([(NSObject *)itemProviderItem isKindOfClass:[NSData class]])
                {
                    imageData = (NSData*)itemProviderItem;
                }
                else if ([(NSObject *)itemProviderItem isKindOfClass:[NSURL class]])
                {
                    NSURL *imageURL = (NSURL*)itemProviderItem;
                    imageData = [NSData dataWithContentsOfURL:imageURL];
                }
                else if ([(NSObject *)itemProviderItem isKindOfClass:[UIImage class]])
                {
                    // An application can share directly an UIImage.
                    // The most common case is screenshot sharing without saving to file.
                    // As screenshot using PNG format when they are saved to file we also use PNG format when saving UIImage to NSData.
                    UIImage *image = (UIImage*)itemProviderItem;
                    imageData = UIImagePNGRepresentation(image);
                }
                
                if (!imageData)
                {
                    requestFailure(error);
                    return;
                }
                
                if ([self.shareItemProvider areAllItemsImages])
                {
                    // When all items are images, they're processed together from the
                    // pending list, immediately after the final image has been loaded.
                    [self.pendingImages addObject:imageData];
                }
                else
                {
                    // Otherwise, the image is sent as is, without prompting for a resize
                    // as that wouldn't make much sense with multiple content types.
                    self.imageCompressionMode = ImageCompressionModeNone;
                    [self sendImageData:imageData toRooms:rooms success:requestSuccess failure:requestFailure];
                }
                
                // When there are multiple content types the image will have been sent above.
                // Otherwise, if we have loaded all of the images we can send them all together.
                if ([self.shareItemProvider areAllItemsImages])
                {
                    if ([self.shareItemProvider areAllItemsLoaded])
                    {
                        MXWeakify(self);
                        void (^sendPendingImages)(void) = ^void() {
                            MXStrongifyAndReturnIfNil(self);
                            [self sendImageDatas:self.pendingImages.copy toRooms:rooms success:requestSuccess failure:requestFailure];
                        };
                        
                        if (RiotSettings.shared.showMediaCompressionPrompt)
                        {
                            // Create a compression prompt which will be nil when the sizes can't be determined or if there are no pending images.
                            UIAlertController *compressionPrompt = [self compressionPromptForPendingImagesWithShareBlock:sendPendingImages];
                            if (compressionPrompt)
                            {
                                [self presentCompressionPrompt:compressionPrompt];
                            }
                        }
                        else
                        {
                            self.imageCompressionMode = ImageCompressionModeNone;
                            sendPendingImages();
                        }
                    }
                    else
                    {
                        dispatch_group_leave(dispatchGroup);
                    }
                }
            }];
        }
    }
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        [self resetPendingData];
        
        if (errors)
        {
            failure(errors);
        }
        else
        {
            success();
        }
    });
}

// TODO: When select multiple images:
// - Enhance prompt to display sum of all file sizes for each compression.
// - Find a way to choose compression sizes for all images.
- (UIAlertController *)compressionPromptForPendingImagesWithShareBlock:(void(^)(void))shareBlock
{
    if (!self.pendingImages.count)
    {
        return nil;
    }
    
    NSData *firstImageData = self.pendingImages.firstObject;
    UIImage *firstImage = [UIImage imageWithData:firstImageData];
    
    MXKImageCompressionSizes compressionSizes = [MXKTools availableCompressionSizesForImage:firstImage originalFileSize:firstImageData.length];
    
    if (compressionSizes.small.fileSize == 0 && compressionSizes.medium.fileSize == 0 && compressionSizes.large.fileSize == 0)
    {
        self.imageCompressionMode = ImageCompressionModeNone;
        MXLogDebug(@"[ShareManager] Bypass compression prompt and send originals for %lu image(s) due to undetermined file sizes", (unsigned long)self.pendingImages.count);
        
        shareBlock();
        
        return nil;
    }
    
    UIAlertController *compressionPrompt = [UIAlertController alertControllerWithTitle:[VectorL10n attachmentSizePromptTitle]
                                                                               message:[VectorL10n attachmentSizePromptMessage]
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (compressionSizes.small.fileSize)
    {
        NSString *title = [VectorL10n attachmentSmall:[MXTools fileSizeToString:compressionSizes.small.fileSize]];
        
        MXWeakify(self);
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            self.imageCompressionMode = ImageCompressionModeSmall;
            [self logCompressionSizeChoice:compressionSizes.small];
            
            shareBlock();
        }]];
    }
    
    if (compressionSizes.medium.fileSize)
    {
        NSString *title = [VectorL10n attachmentMedium:[MXTools fileSizeToString:compressionSizes.medium.fileSize]];
        
        MXWeakify(self);
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            self.imageCompressionMode = ImageCompressionModeMedium;
            [self logCompressionSizeChoice:compressionSizes.medium];
            
            shareBlock();
        }]];
    }
    
    // Do not offer the possibility to resize an image with a dimension above kLargeImageSizeMaxDimension, to prevent the risk of memory limit exception.
    // TODO: Remove this condition when issue https://github.com/vector-im/riot-ios/issues/2341 will be fixed.
    if (compressionSizes.large.fileSize && (MAX(compressionSizes.large.imageSize.width, compressionSizes.large.imageSize.height) <= kLargeImageSizeMaxDimension))
    {
        NSString *title = [VectorL10n attachmentLarge:[MXTools fileSizeToString:compressionSizes.large.fileSize]];
        
        MXWeakify(self);
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            self.imageCompressionMode = ImageCompressionModeLarge;
            self.actualLargeSize = compressionSizes.actualLargeSize;
            
            [self logCompressionSizeChoice:compressionSizes.large];
            
            shareBlock();
        }]];
    }
    
    // To limit memory consumption when encrypting, we suggest the original resolution only if the image size is moderate
    if (compressionSizes.original.fileSize < kImageMaxFileSize)
    {
        NSString *fileSizeString = [MXTools fileSizeToString:compressionSizes.original.fileSize];
        
        NSString *title = [VectorL10n attachmentOriginal:fileSizeString];
        
        MXWeakify(self);
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            MXStrongifyAndReturnIfNil(self);
            
            self.imageCompressionMode = ImageCompressionModeNone;
            [self logCompressionSizeChoice:compressionSizes.original];
            
            shareBlock();
        }]];
    }
    
    [compressionPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
    
    return compressionPrompt;
}

- (NSString*)utiFromImageData:(NSData*)imageData
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    NSString *uti = (NSString*)CGImageSourceGetType(imageSource);
    CFRelease(imageSource);
    return uti;
}

- (NSString*)mimeTypeFromUTI:(NSString*)uti
{
    return (__bridge_transfer NSString *) UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)uti, kUTTagClassMIMEType);
}

- (BOOL)isResizingSupportedForImageData:(NSData*)imageData
{
    NSString *imageUTI = [self utiFromImageData:imageData];
    return [self isResizingSupportedForUTI:imageUTI];
}

- (BOOL)isResizingSupportedForUTI:(NSString*)imageUTI
{
    if ([imageUTI isEqualToString:(__bridge NSString *)kUTTypePNG] || [imageUTI isEqualToString:(__bridge NSString *)kUTTypeJPEG])
    {
        return YES;
    }
    return NO;
}

- (CGSize)imageSizeFromImageData:(NSData*)imageData
{
    CGFloat width = 0.0f;
    CGFloat height = 0.0f;
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    
    CFRelease(imageSource);
    
    if (imageProperties != NULL)
    {
        CFNumberRef widthNumber  = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
        CFNumberRef heightNumber = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
        CFNumberRef orientationNumber = CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation);
        
        if (widthNumber != NULL)
        {
            CFNumberGetValue(widthNumber, kCFNumberCGFloatType, &width);
        }
        
        if (heightNumber != NULL)
        {
            CFNumberGetValue(heightNumber, kCFNumberCGFloatType, &height);
        }
        
        // Check orientation and flip size if required
        if (orientationNumber != NULL)
        {
            int orientation;
            CFNumberGetValue(orientationNumber, kCFNumberIntType, &orientation);
            
            // For orientation from kCGImagePropertyOrientationLeftMirrored to kCGImagePropertyOrientationLeft flip size
            if (orientation >= 5)
            {
                CGFloat tempWidth = width;
                width = height;
                height = tempWidth;
            }
        }
        
        CFRelease(imageProperties);
    }
    
    return CGSizeMake(width, height);
}

- (void)logCompressionSizeChoice:(MXKImageCompressionSize)compressionSize
{
    NSString *fileSize = [MXTools fileSizeToString:compressionSize.fileSize round:NO];
    NSUInteger imageWidth = compressionSize.imageSize.width;
    NSUInteger imageHeight = compressionSize.imageSize.height;
    
    MXLogDebug(@"[ShareItemSender] User choose image compression with output size %lu x %lu (output file size: %@)", (unsigned long)imageWidth, (unsigned long)imageHeight, fileSize);
    MXLogDebug(@"[ShareItemSender] Number of images to send: %lu", (unsigned long)self.pendingImages.count);
}

#pragma mark - Notifications

- (void)onMediaLoaderStateDidChange:(NSNotification *)notification
{
    MXMediaLoader *loader = (MXMediaLoader*)notification.object;
    // Consider only upload progress
    switch (loader.state) {
        case MXMediaLoaderStateUploadInProgress:
        {
            self.imageUploadProgresses[loader.uploadId] = (NSNumber *)loader.statisticsDict[kMXMediaLoaderProgressValueKey];
            
            const NSInteger totalImagesCount = self.pendingImages.count;
            CGFloat totalProgress = 0.0;
            
            for (NSNumber *progress in self.imageUploadProgresses.allValues)
            {
                totalProgress += progress.floatValue/totalImagesCount;
            }
            
            [self.delegate shareItemSender:self didUpdateProgress:totalProgress];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Sharing

- (void)sendText:(NSString *)text
         toRooms:(NSArray<MXRoom *> *)rooms
         success:(dispatch_block_t)success
         failure:(void(^)(NSError *error))failure
{
    [self didStartSending];
    if (!text)
    {
        MXLogError(@"[ShareItemSender] Invalid text.");
        failure(nil);
        return;
    }
    
    __block NSError *error = nil;
    dispatch_group_t dispatchGroup = dispatch_group_create();
    for (MXRoom *room in rooms) {
        dispatch_group_enter(dispatchGroup);
        [room sendTextMessage:text threadId:nil success:^(NSString *eventId) {
            dispatch_group_leave(dispatchGroup);
        } failure:^(NSError *innerError) {
            MXLogErrorDetails(@"[ShareItemSender] sendTextMessage failed with error", @{
                @"error": error ?: @"unknown"
            });
            error = innerError;
            dispatch_group_leave(dispatchGroup);
        }];
    }
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        if(error) {
            failure(error);
        } else {
            success();
        }
    });
}

- (void)sendFileWithUrl:(NSURL *)fileUrl
                toRooms:(NSArray<MXRoom *> *)rooms
                success:(dispatch_block_t)success
                failure:(void(^)(NSError *error))failure
{
    [self didStartSending];
    if (!fileUrl)
    {
        MXLogError(@"[ShareItemSender] Invalid file url.");
        failure(nil);
        return;
    }
    
    NSString *mimeType;
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[fileUrl pathExtension] , NULL);
    mimeType = [self mimeTypeFromUTI:(__bridge NSString *)uti];
    CFRelease(uti);
    
    __block NSError *error = nil;
    dispatch_group_t dispatchGroup = dispatch_group_create();
    for (MXRoom *room in rooms) {
        dispatch_group_enter(dispatchGroup);
        [room sendFile:fileUrl mimeType:mimeType threadId:nil localEcho:nil success:^(NSString *eventId) {
            dispatch_group_leave(dispatchGroup);
        } failure:^(NSError *innerError) {
            MXLogErrorDetails(@"[ShareItemSender] sendFile failed with error", @{
                @"error": innerError ?: @"unknown"
            });
            error = innerError;
            dispatch_group_leave(dispatchGroup);
        } keepActualFilename:YES];
    }
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        if(error) {
            failure(error);
        } else {
            success();
        }
    });
}

- (void)sendVideo:(NSURL *)videoLocalUrl
          toRooms:(NSArray<MXRoom *> *)rooms
          success:(dispatch_block_t)success
          failure:(void(^)(NSError *error))failure
{
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoLocalUrl options:nil];
    
    MXWeakify(self);
    
    void (^sendVideo)(void) = ^void()  {
        MXStrongifyAndReturnIfNil(self);
        
        [self didStartSending];
        if (!videoLocalUrl)
        {
            MXLogError(@"[ShareManager] Invalid video file url.");
            failure(nil);
            return;
        }
        
        // Retrieve the video frame at 1 sec to define the video thumbnail
        AVAssetImageGenerator *assetImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:videoAsset];
        assetImageGenerator.appliesPreferredTrackTransform = YES;
        CMTime time = CMTimeMake(1, 1);
        CGImageRef imageRef = [assetImageGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
        // Finalize video attachment
        UIImage *videoThumbnail = [[UIImage alloc] initWithCGImage:imageRef];
        CFRelease(imageRef);
        
        __block NSError *error = nil;
        dispatch_group_t dispatchGroup = dispatch_group_create();
        for (MXRoom *room in rooms) {
            dispatch_group_enter(dispatchGroup);
            [room sendVideoAsset:videoAsset withThumbnail:videoThumbnail threadId:nil localEcho:nil success:^(NSString *eventId) {
                dispatch_group_leave(dispatchGroup);
            } failure:^(NSError *innerError) {
                MXLogErrorDetails(@"[ShareManager] Failed sending video with error", @{
                    @"error": innerError ?: @"unknown"
                });
                error = innerError;
                dispatch_group_leave(dispatchGroup);
            }];
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            if(error) {
                failure(error);
            } else {
                success();
            }
        });
    };
    
    BOOL allRoomsAreUnencrypted = ![self roomsContainEncryptedRoom:rooms];
    
    // When rooms are unencrypted convert the video according to the user's normal preferences
    if (allRoomsAreUnencrypted)
    {
        if (!RiotSettings.shared.showMediaCompressionPrompt)
        {
            [MXSDKOptions sharedInstance].videoConversionPresetName = AVAssetExportPreset1920x1080;
            sendVideo();
        }
        else
        {
            UIAlertController *compressionPrompt = [MXKTools videoConversionPromptForVideoAsset:videoAsset withCompletion:^(NSString *presetName) {
                // If the preset name is nil, the user cancelled.
                if (!presetName)
                {
                    return;
                }
                
                // Set the chosen video conversion preset.
                [MXSDKOptions sharedInstance].videoConversionPresetName = presetName;
                sendVideo();
            }];
            
            [self presentCompressionPrompt:compressionPrompt];
        }
    }
    else
    {
        // When rooms are encrypted we quickly run out of memory encrypting the video
        // Prompt the user if they're happy to send a low quality video (320p).
        UIAlertController *lowQualityPrompt = [UIAlertController alertControllerWithTitle:VectorL10n.shareExtensionLowQualityVideoTitle
                                                                                  message:[VectorL10n shareExtensionLowQualityVideoMessage:AppInfo.current.displayName]
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:VectorL10n.cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            // Do nothing
        }];
        UIAlertAction *sendAction = [UIAlertAction actionWithTitle:VectorL10n.shareExtensionSendNow style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MXSDKOptions sharedInstance].videoConversionPresetName = AVAssetExportPresetMediumQuality;
            sendVideo();
        }];
        
        [lowQualityPrompt addAction:cancelAction];
        [lowQualityPrompt addAction:sendAction];
        [lowQualityPrompt setPreferredAction:sendAction];
        
        [self presentCompressionPrompt:lowQualityPrompt];
    }
}

- (void)sendVoiceMessage:(NSURL *)fileUrl
                 toRooms:(NSArray<MXRoom *> *)rooms
                 success:(dispatch_block_t)success
                 failure:(void(^)(NSError *error))failure
{
    [self didStartSending];
    if (!fileUrl)
    {
        MXLogError(@"[ShareItemSender] Invalid voice message file url.");
        failure(nil);
        return;
    }
    
    __block NSError *error = nil;
    dispatch_group_t dispatchGroup = dispatch_group_create();
    for (MXRoom *room in rooms) {
        dispatch_group_enter(dispatchGroup);
        [room sendVoiceMessage:fileUrl mimeType:nil duration:0.0 samples:nil threadId:nil localEcho:nil success:^(NSString *eventId) {
            dispatch_group_leave(dispatchGroup);
        } failure:^(NSError *innerError) {
            MXLogErrorDetails(@"[ShareItemSender] sendVoiceMessage failed with error", @{
                @"error": error ?: @"unknown"
            });
            error = innerError;
            dispatch_group_leave(dispatchGroup);
        } keepActualFilename:YES];
    }
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        if(error) {
            failure(error);
        } else {
            success();
        }
    });
}

- (void)sendImageDatas:(NSArray<id<ShareItemProtocol>> *)imageDatas
               toRooms:(NSArray<MXRoom *> *)rooms
               success:(dispatch_block_t)success
               failure:(void(^)(NSError *error))failure
{
    if (imageDatas.count == 0)
    {
        MXLogError(@"[ShareManager] sendImages: no images to send.");
        failure(nil);
        return;
    }
    
    [self didStartSending];
    
    dispatch_group_t requestsGroup = dispatch_group_create();
    __block NSError *firstRequestError;
    
    NSUInteger index = 0;
    
    for (NSData *imageData in imageDatas)
    {
        @autoreleasepool
        {
            dispatch_group_enter(requestsGroup);
            [self sendImageData:imageData toRooms:rooms success:^{
                dispatch_group_leave(requestsGroup);
            } failure:^(NSError *error) {
                if (error && !firstRequestError)
                {
                    firstRequestError = error;
                }
                
               dispatch_group_leave(requestsGroup);
            }];
        }
        
        index++;
    }
    
    dispatch_group_notify(requestsGroup, dispatch_get_main_queue(), ^{
        
        if (firstRequestError)
        {
            failure(firstRequestError);
        }
        else
        {
            success();
        }
    });
}

- (void)sendImageData:(NSData *)imageData
              toRooms:(NSArray<MXRoom *> *)rooms
              success:(dispatch_block_t)success
              failure:(void(^)(NSError *error))failure
{
    [self didStartSending];
    
    NSString *imageUTI;
    NSString *mimeType;
    
    if (!mimeType)
    {
        imageUTI = [self utiFromImageData:imageData];
        if (imageUTI)
        {
            mimeType = [self mimeTypeFromUTI:imageUTI];
        }
    }
    
    if (!mimeType)
    {
        MXLogError(@"[ShareManager] sendImage failed. Cannot determine MIME type .");
        if (failure)
        {
            failure(nil);
        }
        return;
    }
    
    CGSize imageSize;
    NSData *finalImageData;
    
    // Only resize JPEG or PNG files
    if ([self isResizingSupportedForUTI:imageUTI])
    {
        UIImage *convertedImage;
        CGSize newImageSize;
        
        switch (self.imageCompressionMode) {
            case ImageCompressionModeSmall:
                newImageSize = CGSizeMake(MXKTOOLS_SMALL_IMAGE_SIZE, MXKTOOLS_SMALL_IMAGE_SIZE);
                break;
            case ImageCompressionModeMedium:
                newImageSize = CGSizeMake(MXKTOOLS_MEDIUM_IMAGE_SIZE, MXKTOOLS_MEDIUM_IMAGE_SIZE);
                break;
            case ImageCompressionModeLarge:
                newImageSize = CGSizeMake(self.actualLargeSize, self.actualLargeSize);
                break;
            default:
                newImageSize = CGSizeZero;
                break;
        }
        
        if (!CGSizeEqualToSize(newImageSize, CGSizeZero))
        {
            // Resize the image and set image in right orientation too
            convertedImage = [MXKTools resizeImageWithData:imageData toFitInSize:newImageSize];
        }
        
        if (convertedImage)
        {
            if ([imageUTI isEqualToString:(__bridge NSString *)kUTTypePNG])
            {
                finalImageData = UIImagePNGRepresentation(convertedImage);
            }
            else if ([imageUTI isEqualToString:(__bridge NSString *)kUTTypeJPEG])
            {
                finalImageData = UIImageJPEGRepresentation(convertedImage, 0.9);
            }
            
            imageSize = convertedImage.size;
        }
        else
        {
            finalImageData = imageData;
            imageSize = [self imageSizeFromImageData:imageData];
        }
    }
    else
    {
        finalImageData = imageData;
        imageSize = [self imageSizeFromImageData:imageData];
    }
    
    __block NSError *error = nil;
    dispatch_group_t dispatchGroup = dispatch_group_create();
    for (MXRoom *room in rooms) {
                
        UIImage *thumbnail = nil;
        if (room.summary.isEncrypted) // Thumbnail is useful only in case of encrypted room
        {
            thumbnail = [MXKTools resizeImageWithData:imageData toFitInSize:kThumbnailSize];
        }
        
        dispatch_group_enter(dispatchGroup);
        [room sendImage:finalImageData withImageSize:imageSize mimeType:mimeType andThumbnail:thumbnail threadId:nil localEcho:nil success:^(NSString *eventId) {
            dispatch_group_leave(dispatchGroup);
        } failure:^(NSError *innerError) {
            MXLogErrorDetails(@"[ShareManager] sendImage failed with error", @{
                @"error": error ?: @"unknown"
            });
            error = innerError;
            dispatch_group_leave(dispatchGroup);
        }];
    }
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        if(error) {
            failure(error);
        } else {
            success();
        }
    });
}

@end
