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
#import "SharePresentingViewController.h"
#import <MatrixKit/MatrixKit.h>
@import MobileCoreServices;
#import "objc/runtime.h"
#include <MatrixSDK/MXUIKitBackgroundModeHandler.h>

NSString *const kShareExtensionManagerDidUpdateAccountDataNotification = @"kShareExtensionManagerDidUpdateAccountDataNotification";

typedef NS_ENUM(NSInteger, ImageCompressionMode)
{
    ImageCompressionModeNone,
    ImageCompressionModeSmall,
    ImageCompressionModeMedium,
    ImageCompressionModeLarge
};


@interface ShareExtensionManager ()

@property (nonatomic, readwrite) MXKAccount *userAccount;

@property (nonatomic) NSMutableArray <NSData *> *pendingImages;
@property (nonatomic) NSMutableDictionary <NSString *, NSNumber *> *imageUploadProgresses;
@property (nonatomic) ImageCompressionMode imageCompressionMode;
@property (nonatomic) CGFloat actualLargeSize;

@end


@implementation ShareExtensionManager

#pragma mark - Lifecycle

+ (instancetype)sharedManager
{
    static ShareExtensionManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[self alloc] init];
        
        sharedInstance.pendingImages = [NSMutableArray array];
        sharedInstance.imageUploadProgresses = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(onMediaLoaderStateDidChange:) name:kMXMediaLoaderStateDidChangeNotification object:nil];
        
        // Add observer to handle logout
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(checkUserAccount) name:kMXKAccountManagerDidRemoveAccountNotification object:nil];
        
        // Add observer on the Extension host
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(checkUserAccount) name:NSExtensionHostWillEnterForegroundNotification object:nil];
        
        MXSDKOptions *sdkOptions = [MXSDKOptions sharedInstance];
        // Apply the application group
        sdkOptions.applicationGroupIdentifier = @"group.im.vector";
        // Disable identicon use
        sdkOptions.disableIdenticonUseForUserAvatar = YES;
        // Enable e2e encryption for newly created MXSession
        sdkOptions.enableCryptoWhenStartingMXSession = YES;
        // Use UIKit BackgroundTask for handling background tasks in the SDK
        sdkOptions.backgroundModeHandler = [[MXUIKitBackgroundModeHandler alloc] init];
        
        // Customize the localized string table
        [NSBundle mxk_customizeLocalizedStringTableName:@"Vector"];

        // NSLog -> console.log file when not debugging the app
        if (!isatty(STDERR_FILENO))
        {
            [MXLogger setSubLogName:@"share"];
            [MXLogger redirectNSLogToFiles:YES];
        }
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
            self.userAccount = nil;
        }
    }
    
    if (!self.userAccount)
    {
        // We consider the first enabled account.
        // TODO: Handle multiple accounts
        self.userAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    }
    
    // Reset the file store to reload the room data.
    if (_fileStore)
    {
        [_fileStore close];
        _fileStore = nil;
    }
    
    if (self.userAccount)
    {
        _fileStore = [[MXFileStore alloc] initWithCredentials:self.userAccount.mxCredentials];
    }
    
    // Post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kShareExtensionManagerDidUpdateAccountDataNotification object:self.userAccount userInfo:nil];
}

#pragma mark - Public

- (void)setShareExtensionContext:(NSExtensionContext *)shareExtensionContext
{
    _shareExtensionContext = shareExtensionContext;
    
    // Set up runtime language on each context update.
    NSUserDefaults *sharedUserDefaults = [MXKAppSettings standardAppSettings].sharedUserDefaults;
    NSString *language = [sharedUserDefaults objectForKey:@"appLanguage"];
    [NSBundle mxk_setLanguage:language];
    [NSBundle mxk_setFallbackLanguage:@"en"];
    
    // Check the current matrix user.
    [self checkUserAccount];
}

- (void)sendContentToRoom:(MXRoom *)room failureBlock:(void(^)(NSError *error))failureBlock
{
    NSString *UTTypeText = (__bridge NSString *)kUTTypeText;
    NSString *UTTypeURL = (__bridge NSString *)kUTTypeURL;
    NSString *UTTypeImage = (__bridge NSString *)kUTTypeImage;
    NSString *UTTypeVideo = (__bridge NSString *)kUTTypeVideo;
    NSString *UTTypeFileUrl = (__bridge NSString *)kUTTypeFileURL;
    NSString *UTTypeMovie = (__bridge NSString *)kUTTypeMovie;
    
    __weak typeof(self) weakSelf = self;
    
    [self resetPendingData];
    
    for (NSExtensionItem *item in self.shareExtensionContext.inputItems)
    {
        for (NSItemProvider *itemProvider in item.attachments)
        {
            if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeFileUrl])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeFileUrl options:nil completionHandler:^(NSURL *fileUrl, NSError * _Null_unspecified error) {
                    
                    // Switch back on the main thread to handle correctly the UI change
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (weakSelf)
                        {
                            typeof(self) self = weakSelf;
                            [self sendFileWithUrl:fileUrl toRoom:room extensionItem:item failureBlock:failureBlock];
                        }
                        
                    });
                    
                }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeText])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeText options:nil completionHandler:^(NSString *text, NSError * _Null_unspecified error) {
                    
                    // Switch back on the main thread to handle correctly the UI change
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (weakSelf)
                        {
                            typeof(self) self = weakSelf;
                            [self sendText:text toRoom:room extensionItem:item failureBlock:failureBlock];
                        }
                        
                    });
                    
                }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeURL])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeURL options:nil completionHandler:^(NSURL *url, NSError * _Null_unspecified error) {
                    
                    // Switch back on the main thread to handle correctly the UI change
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (weakSelf)
                        {
                            typeof(self) self = weakSelf;
                            [self sendText:url.absoluteString toRoom:room extensionItem:item failureBlock:failureBlock];
                        }
                        
                    });
                    
                }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeImage])
            {
                itemProvider.isLoaded = NO;
                
                [itemProvider loadItemForTypeIdentifier:UTTypeImage options:nil completionHandler:^(id<NSSecureCoding> _Nullable itemProviderItem, NSError * _Null_unspecified error)
                 {
                     if (weakSelf)
                     {
                         typeof(self) self = weakSelf;
                         itemProvider.isLoaded = YES;
                         
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
                         
                         if (imageData)
                         {
                             [self.pendingImages addObject:imageData];
                         }
                         else
                         {
                             NSLog(@"[ShareExtensionManager] sendContentToRoom: failed to loadItemForTypeIdentifier. Error: %@", error);
                         }
                         
                         if ([self areAttachmentsFullyLoaded])
                         {
                             UIAlertController *compressionPrompt = [self compressionPromptForPendingImagesWithShareBlock:^{
                                 [self sendImages:self.pendingImages withProviders:item.attachments toRoom:room extensionItem:item failureBlock:failureBlock];
                             }];
                             
                             if (compressionPrompt)
                             {
                                 [self.delegate shareExtensionManager:self showImageCompressionPrompt:compressionPrompt];
                             }
                         }
                     }
                 }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeVideo])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeVideo options:nil completionHandler:^(NSURL *videoLocalUrl, NSError * _Null_unspecified error) {
                     
                     // Switch back on the main thread to handle correctly the UI change
                     dispatch_async(dispatch_get_main_queue(), ^{
                         
                         if (weakSelf)
                         {
                             typeof(self) self = weakSelf;
                             [self sendVideo:videoLocalUrl toRoom:room extensionItem:item failureBlock:failureBlock];
                         }
                         
                     });
                    
                 }];
            }
            else if ([itemProvider hasItemConformingToTypeIdentifier:UTTypeMovie])
            {
                [itemProvider loadItemForTypeIdentifier:UTTypeMovie options:nil completionHandler:^(NSURL *videoLocalUrl, NSError * _Null_unspecified error) {
                     
                     // Switch back on the main thread to handle correctly the UI change
                     dispatch_async(dispatch_get_main_queue(), ^{
                         
                         if (weakSelf)
                         {
                             typeof(self) self = weakSelf;
                             [self sendVideo:videoLocalUrl toRoom:room extensionItem:item failureBlock:failureBlock];
                         }
                         
                     });
                     
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
    if (canceled)
    {
        [self.shareExtensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXUserCancelErrorDomain" code:4201 userInfo:nil]];
    }
    else
    {
        [self.shareExtensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXFailureErrorDomain" code:500 userInfo:nil]];
    }
    
    [self.primaryViewController destroy];
    self.primaryViewController = nil;
    
    // FIXME: Share extension memory usage increase when launched several times and then crash due to some memory leaks.
    // For now, we force the share extension to exit and free memory.
    [NSException raise:@"Kill the app extension" format:@"Free memory used by share extension"];
}

#pragma mark - Private

- (void)resetPendingData
{
    [self.pendingImages removeAllObjects];
    [self.imageUploadProgresses removeAllObjects];
}

- (void)completeRequestReturningItems:(nullable NSArray *)items completionHandler:(void(^ __nullable)(BOOL expired))completionHandler;
{
    [self.shareExtensionContext completeRequestReturningItems:items completionHandler:completionHandler];
    
    [self.primaryViewController destroy];
    self.primaryViewController = nil;
    
    // FIXME: Share extension memory usage increase when launched several times and then crash due to some memory leaks.
    // For now, we force the share extension to exit and free memory.
    [NSException raise:@"Kill the app extension" format:@"Free memory used by share extension"];
}

- (BOOL)isAPendingImageNotOrientedUp
{
    BOOL isAPendingImageNotOrientedUp = NO;
    
    for (NSData *imageData in self.pendingImages)
    {
        if ([self isImageOrientationNotUpOrUndeterminedForImageData:imageData])
        {
            isAPendingImageNotOrientedUp = YES;
            break;
        }
    }
    
    return isAPendingImageNotOrientedUp;
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
    
    UIAlertController *compressionPrompt;
    BOOL isAPendingImageNotOrientedUp = [self isAPendingImageNotOrientedUp];
    
    NSData *firstImageData = self.pendingImages.firstObject;
    UIImage *firstImage = [UIImage imageWithData:firstImageData];
    
    // Get available sizes for this image
    MXKImageCompressionSizes compressionSizes = [MXKTools availableCompressionSizesForImage:firstImage originalFileSize:firstImageData.length];
    
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
                                                                    }
                                                                    
                                                                }]];
        }
        
        // To limit memory consumption, we suggest the original resolution only if the image orientation is up, or if the image size is moderate
        if (!isAPendingImageNotOrientedUp || !compressionSizes.large.fileSize)
        {
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
                                                                    }
                                                                    
                                                                }]];
        }
        
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil]];
        
        
    }
    else
    {
        if (isAPendingImageNotOrientedUp && self.pendingImages.count > 1)
        {
            self.imageCompressionMode = ImageCompressionModeSmall;
        }
        else
        {
            self.imageCompressionMode = ImageCompressionModeNone;
        }
        
        if (shareBlock)
        {
            shareBlock();
        }
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

- (BOOL)areAttachmentsFullyLoaded
{
    for (NSExtensionItem *item in self.shareExtensionContext.inputItems)
    {
        for (NSItemProvider *itemProvider in item.attachments)
        {
            if (itemProvider.isLoaded == NO)
            {
                return NO;
            }
        }
    }
    return YES;
}

- (NSString*)utiFromImageTypeItemProvider:(NSItemProvider*)itemProvider
{
    NSString *uti;
    
    NSString *utiPNG = (__bridge NSString *)kUTTypePNG;
    NSString *utiJPEG = (__bridge NSString *)kUTTypeJPEG;
    
    if ([itemProvider hasItemConformingToTypeIdentifier:utiPNG])
    {
        uti = utiPNG;
    }
    else if ([itemProvider hasItemConformingToTypeIdentifier:utiJPEG])
    {
        uti = utiJPEG;
    }
    else
    {
        uti = itemProvider.registeredTypeIdentifiers.firstObject;
    }
    
    return uti;
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

- (NSNumber*)cgImageimageOrientationNumberFromImageData:(NSData*)imageData
{
    NSNumber *orientationNumber;
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    
    CFRelease(imageSource);
    
    if (imageProperties != NULL)
    {
        CFNumberRef orientationNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation);
        
        // Check orientation and flip size if required
        if (orientationNum != NULL)
        {
            orientationNumber = (__bridge NSNumber *)orientationNum;
        }
        
        CFRelease(imageProperties);
    }
    
    return orientationNumber;
}

- (BOOL)isImageOrientationNotUpOrUndeterminedForImageData:(NSData*)imageData
{
    BOOL isImageNotOrientedUp = YES;
    
    NSNumber *cgImageOrientationNumber = [self cgImageimageOrientationNumberFromImageData:imageData];
    
    if (cgImageOrientationNumber && cgImageOrientationNumber.unsignedIntegerValue == (NSUInteger)kCGImagePropertyOrientationUp)
    {
        isImageNotOrientedUp = NO;
    }
    
    return isImageNotOrientedUp;
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
            if ([self.delegate respondsToSelector:@selector(shareExtensionManager:mediaUploadProgress:)])
            {
                const NSInteger totalImagesCount = self.pendingImages.count;
                CGFloat totalProgress = 0.0;
                
                for (NSNumber *progress in self.imageUploadProgresses.allValues)
                {
                    totalProgress += progress.floatValue/totalImagesCount;
                }
                
                [self.delegate shareExtensionManager:self mediaUploadProgress:totalProgress];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - Sharing

- (void)sendText:(NSString *)text toRoom:(MXRoom *)room extensionItem:(NSExtensionItem *)extensionItem failureBlock:(void(^)(NSError *error))failureBlock
{
    [self didStartSendingToRoom:room];
    if (!text)
    {
        NSLog(@"[ShareExtensionManager] loadItemForTypeIdentifier: failed.");
        if (failureBlock)
        {
            failureBlock(nil);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [room sendTextMessage:text success:^(NSString *eventId) {
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            [self completeRequestReturningItems:@[extensionItem] completionHandler:nil];
        }
    } failure:^(NSError *error) {
        NSLog(@"[ShareExtensionManager] sendTextMessage failed.");
        if (failureBlock)
        {
            failureBlock(error);
        }
    }];
}

- (void)sendFileWithUrl:(NSURL *)fileUrl toRoom:(MXRoom *)room extensionItem:(NSExtensionItem *)extensionItem failureBlock:(void(^)(NSError *error))failureBlock
{
    [self didStartSendingToRoom:room];
    if (!fileUrl)
    {
        NSLog(@"[ShareExtensionManager] loadItemForTypeIdentifier: failed.");
        if (failureBlock)
        {
            failureBlock(nil);
        }
        return;
    }
    
    NSString *mimeType;
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[fileUrl pathExtension] , NULL);
    mimeType = [self mimeTypeFromUTI:(__bridge NSString *)uti];
    CFRelease(uti);
    
    __weak typeof(self) weakSelf = self;
    
    [room sendFile:fileUrl mimeType:mimeType localEcho:nil success:^(NSString *eventId) {
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            [self completeRequestReturningItems:@[extensionItem] completionHandler:nil];
        }
    } failure:^(NSError *error) {
        NSLog(@"[ShareExtensionManager] sendFile failed.");
        if (failureBlock)
        {
            failureBlock(error);
        }
    } keepActualFilename:YES];
}


- (void)sendImages:(NSMutableArray *)imageDatas withProviders:(NSArray*)itemProviders toRoom:(MXRoom *)room extensionItem:(NSExtensionItem *)extensionItem failureBlock:(void(^)(NSError *error))failureBlock
{
    if (imageDatas.count == 0)
    {
        NSLog(@"[ShareExtensionManager] sendImages: no images to send.");
        
        if (failureBlock)
        {
            failureBlock(nil);
        }
        return;
    }
    
    [self didStartSendingToRoom:room];
    
    __block NSUInteger count = imageDatas.count;
    
    for (NSInteger index = 0; index < imageDatas.count; index++)
    {
        @autoreleasepool
        {
            NSItemProvider *itemProvider = itemProviders[index];
            NSData *imageData = imageDatas[index];
            
            NSString *imageUTI;
            NSString *mimeType;
            
            // Try to get UTI plus mime type from NSItemProvider
            imageUTI = [self utiFromImageTypeItemProvider:itemProvider];
            
            if (imageUTI)
            {
                mimeType = [self mimeTypeFromUTI:imageUTI];
            }
            
            if (!mimeType)
            {
                // Try to get UTI plus mime type from image data
                
                imageUTI = [self utiFromImageData:imageData];
                
                if (imageUTI)
                {
                    mimeType = [self mimeTypeFromUTI:imageUTI];
                }
            }
            
            // Sanity check
            if (!mimeType)
            {
                NSLog(@"[ShareExtensionManager] sendImage failed. Cannot determine MIME type of %@", itemProvider);
                if (failureBlock)
                {
                    failureBlock(nil);
                }
                return;
            }
            
            CGSize imageSize;
            
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
                
                if (CGSizeEqualToSize(newImageSize, CGSizeZero))
                {
                    // No resize to make
                    // Make sure the uploaded image orientation is up
                    if ([self isImageOrientationNotUpOrUndeterminedForImageData:imageData])
                    {
                        UIImage *image = [UIImage imageWithData:imageData];
                        convertedImage = [MXKTools forceImageOrientationUp:image];
                    }
                }
                else
                {
                    // Resize the image and set image in right orientation too
                    convertedImage = [MXKTools resizeImageWithData:imageData toFitInSize:newImageSize];
                }
                
                if (convertedImage)
                {
                    if ([imageUTI isEqualToString:(__bridge NSString *)kUTTypePNG])
                    {
                        imageData = UIImagePNGRepresentation(convertedImage);
                    }
                    else if ([imageUTI isEqualToString:(__bridge NSString *)kUTTypeJPEG])
                    {
                        imageData = UIImageJPEGRepresentation(convertedImage, 0.9);
                    }
                    
                    imageSize = convertedImage.size;
                }
                else
                {
                    imageSize = [self imageSizeFromImageData:imageData];
                }
            }
            else
            {
                imageSize = [self imageSizeFromImageData:imageData];
            }
            
            UIImage *thumbnail = nil;
            // Thumbnail is useful only in case of encrypted room
            if (room.summary.isEncrypted)
            {
                thumbnail = [MXKTools resizeImageWithData:imageData toFitInSize:CGSizeMake(800, 600)];
            }
            
            __weak typeof(self) weakSelf = self;
            
            [room sendImage:imageData withImageSize:imageSize mimeType:mimeType andThumbnail:thumbnail localEcho:nil success:^(NSString *eventId) {
                
                if (!--count && weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    [self resetPendingData];
                    [self completeRequestReturningItems:@[extensionItem] completionHandler:nil];
                }
                
            } failure:^(NSError *error) {
                
                NSLog(@"[ShareExtensionManager] sendImage failed.");
                if (failureBlock)
                {
                    failureBlock(error);
                }
                
            }];
            
        }
    }
}

- (void)sendVideo:(NSURL *)videoLocalUrl toRoom:(MXRoom *)room extensionItem:(NSExtensionItem *)extensionItem failureBlock:(void(^)(NSError *error))failureBlock
{
    [self didStartSendingToRoom:room];
    if (!videoLocalUrl)
    {
        NSLog(@"[ShareExtensionManager] loadItemForTypeIdentifier: failed.");
        if (failureBlock)
        {
            failureBlock(nil);
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
            [self completeRequestReturningItems:@[extensionItem] completionHandler:nil];
        }
    } failure:^(NSError *error) {
        NSLog(@"[ShareExtensionManager] sendVideo failed.");
        if (failureBlock)
        {
            failureBlock(error);
        }
    }];
}


@end


@implementation NSItemProvider (ShareExtensionManager)

- (void)setIsLoaded:(BOOL)isLoaded
{
    NSNumber *number = @(isLoaded);
    objc_setAssociatedObject(self, @selector(isLoaded), number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isLoaded
{
    NSNumber *number = objc_getAssociatedObject(self, @selector(isLoaded));
    return number.boolValue;
}

@end
