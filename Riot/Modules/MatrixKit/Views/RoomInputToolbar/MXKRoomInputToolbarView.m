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

#import "MXKRoomInputToolbarView.h"
#import "MXKSwiftHeader.h"
#import "MXKAppSettings.h"

@import MatrixSDK.MXMediaManager;
@import MediaPlayer;
@import MobileCoreServices;
@import Photos;

#import "MXKImageView.h"

#import "MXKTools.h"

#import "NSBundle+MatrixKit.h"
#import "MXKConstants.h"

@interface MXKRoomInputToolbarView()
{
    /**
     Alert used to list options.
     */
    UIAlertController *optionsListView;
    
    /**
     Current media picker
     */
    UIImagePickerController *mediaPicker;
    
    /**
     Array of validation views (MXKImageView instances)
     */
    NSMutableArray *validationViews;
    
    /**
     Handle images attachment
     */
    UIAlertController *compressionPrompt;
    NSMutableArray *pendingImages;
}

@property (nonatomic) IBOutlet UIView *messageComposerContainer;

@end

@implementation MXKRoomInputToolbarView
@synthesize messageComposerContainer, inputAccessoryViewForKeyboard;

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRoomInputToolbarView class])
                          bundle:[NSBundle bundleForClass:[MXKRoomInputToolbarView class]]];
}

+ (instancetype)roomInputToolbarView
{
    if ([[self class] nib])
    {
        return [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    }
    else
    {
        return [[self alloc] init];
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Finalize setup
    [self setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    // Disable send button
    self.rightInputToolbarButton.enabled = NO;
    
    // Enable text edition by default
    self.editable = YES;
    
    // Localize string
    [_rightInputToolbarButton setTitle:[VectorL10n send] forState:UIControlStateNormal];
    [_rightInputToolbarButton setTitle:[VectorL10n send] forState:UIControlStateHighlighted];
    
    validationViews = [NSMutableArray array];
}

- (void)dealloc
{
    inputAccessoryViewForKeyboard = nil;
    
    [self destroy];
}

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    // Reset default container background color
    messageComposerContainer.backgroundColor = [UIColor clearColor];
    
    // Set default toolbar background color
    self.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
}

#pragma mark -

- (IBAction)onTouchUpInside:(UIButton*)button
{
    if (button == self.leftInputToolbarButton)
    {
        if (optionsListView)
        {
            [optionsListView dismissViewControllerAnimated:NO completion:nil];
            optionsListView = nil;
        }
        
        // Option button has been pressed
        // List available options
        __weak typeof(self) weakSelf = self;
        
        // Check whether media attachment is supported
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:presentViewController:)])
        {
            optionsListView = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            [optionsListView addAction:[UIAlertAction actionWithTitle:[VectorL10n attachMedia]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  
                                                                  if (weakSelf)
                                                                  {
                                                                      typeof(self) self = weakSelf;
                                                                      self->optionsListView = nil;
                                                                      
                                                                      // Open media gallery
                                                                      self->mediaPicker = [[UIImagePickerController alloc] init];
                                                                      self->mediaPicker.delegate = self;
                                                                      self->mediaPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                                                      self->mediaPicker.allowsEditing = NO;
                                                                      self->mediaPicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil];
                                                                      [self.delegate roomInputToolbarView:self presentViewController:self->mediaPicker];
                                                                  }
                                                                  
                                                              }]];
            
            [optionsListView addAction:[UIAlertAction actionWithTitle:[VectorL10n captureMedia]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  
                                                                  if (weakSelf)
                                                                  {
                                                                      typeof(self) self = weakSelf;
                                                                      self->optionsListView = nil;
                                                                      
                                                                      // Open Camera
                                                                      self->mediaPicker = [[UIImagePickerController alloc] init];
                                                                      self->mediaPicker.delegate = self;
                                                                      self->mediaPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                                                                      self->mediaPicker.allowsEditing = NO;
                                                                      self->mediaPicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil];
                                                                      [self.delegate roomInputToolbarView:self presentViewController:self->mediaPicker];
                                                                  }
                                                                  
                                                              }]];
        }
        else
        {
            MXLogDebug(@"[MXKRoomInputToolbarView] Attach media is not supported");
        }
        
        // Check whether user invitation is supported
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:inviteMatrixUser:)])
        {
            if (!optionsListView)
            {
                optionsListView = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            }
            
            [optionsListView addAction:[UIAlertAction actionWithTitle:[VectorL10n inviteUser]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  
                                                                  if (weakSelf)
                                                                  {
                                                                      typeof(self) self = weakSelf;
                                                                      
                                                                      // Ask for userId to invite
                                                                      self->optionsListView = [UIAlertController alertControllerWithTitle:[VectorL10n userIdTitle] message:nil preferredStyle:UIAlertControllerStyleAlert];
                                                                      
                                                                      
                                                                      [self->optionsListView addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                          
                                                                          if (weakSelf)
                                                                          {
                                                                              typeof(self) self = weakSelf;
                                                                              self->optionsListView = nil;
                                                                          }
                                                                          
                                                                      }]];
                                                                      
                                                                      [self->optionsListView addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                                                                          
                                                                           textField.secureTextEntry = NO;
                                                                           textField.placeholder = [VectorL10n userIdPlaceholder];
                                                                          
                                                                       }];
                                                                      
                                                                      [self->optionsListView addAction:[UIAlertAction actionWithTitle:[VectorL10n invite] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                          
                                                                          if (weakSelf)
                                                                          {
                                                                              typeof(self) self = weakSelf;
                                                                              
                                                                              UITextField *textField = [self->optionsListView textFields].firstObject;
                                                                              NSString *userId = textField.text;
                                                                              
                                                                              self->optionsListView = nil;
                                                                              
                                                                              if (userId.length)
                                                                              {
                                                                                  [self.delegate roomInputToolbarView:self inviteMatrixUser:userId];
                                                                              }
                                                                          }
                                                                          
                                                                      }]];
                                                                      
                                                                      [self.delegate roomInputToolbarView:self presentAlertController:self->optionsListView];
                                                                  }
                                                                  
                                                              }]];
        }
        else
        {
            MXLogDebug(@"[MXKRoomInputToolbarView] Invitation is not supported");
        }
        
        if (optionsListView)
        {
            
            [self->optionsListView addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    self->optionsListView = nil;
                }
                
            }]];
            
            [optionsListView popoverPresentationController].sourceView = button;
            [optionsListView popoverPresentationController].sourceRect = button.bounds;
            [self.delegate roomInputToolbarView:self presentAlertController:optionsListView];
        }
        else
        {
            MXLogDebug(@"[MXKRoomInputToolbarView] No option is supported");
        }
    }
    else if (button == self.rightInputToolbarButton && self.textMessage.length)
    {
        [self sendCurrentMessage];
    }
}

- (void)sendCurrentMessage
{
    // This forces an autocorrect event to happen when "Send" is pressed, which is necessary to accept a pending correction on send
    self.textMessage = [NSString stringWithFormat:@"%@ ", self.textMessage];
    self.textMessage = [self.textMessage substringToIndex:[self.textMessage length]-1];

    NSString *message = self.textMessage;

    // Reset message, disable view animation during the update to prevent placeholder distorsion.
    [UIView setAnimationsEnabled:NO];
    self.textMessage = nil;
    [UIView setAnimationsEnabled:YES];

    // Send button has been pressed
    if (message.length && [self.delegate respondsToSelector:@selector(roomInputToolbarView:sendTextMessage:)])
    {
        [self.delegate roomInputToolbarView:self sendTextMessage:message];
    }
}

- (void)setPlaceholder:(NSString *)inPlaceholder
{
    _placeholder = inPlaceholder;
}

- (BOOL)becomeFirstResponder
{
    return NO;
}

- (void)dismissKeyboard
{
    
}

- (void)dismissCompressionPrompt
{
    if (compressionPrompt)
    {
        [compressionPrompt dismissViewControllerAnimated:NO completion:nil];
        compressionPrompt = nil;
    }
    
    if (pendingImages.count)
    {
        NSData *firstImage = pendingImages.firstObject;
        [pendingImages removeObjectAtIndex:0];
        [self sendImage:firstImage withCompressionMode:MXKRoomInputToolbarCompressionModePrompt];
    }
}

- (void)destroy
{
    [self dismissValidationViews];
    validationViews = nil;
    
    if (optionsListView)
    {
        [optionsListView dismissViewControllerAnimated:NO completion:nil];
        optionsListView = nil;
    }
    
    [self dismissMediaPicker];
    
    self.delegate = nil;
    
    pendingImages = nil;
    [self dismissCompressionPrompt];
}

- (void)pasteText:(NSString *)text
{
    // We cannot do more than appending text to self.textMessage
    // Let 'MXKRoomInputToolbarView' children classes do the job
    self.textMessage = [NSString stringWithFormat:@"%@%@", self.textMessage, text];
}


#pragma mark - MXKFileSizes

/**
 Structure representing the file sizes of a media according to different level of
 compression.
 */
typedef struct
{
    NSUInteger small;
    NSUInteger medium;
    NSUInteger large;
    NSUInteger original;

} MXKFileSizes;

void MXKFileSizes_init(MXKFileSizes *sizes)
{
    memset(sizes, 0, sizeof(MXKFileSizes));
}

MXKFileSizes MXKFileSizes_add(MXKFileSizes sizes1, MXKFileSizes sizes2)
{
    MXKFileSizes sizes;
    sizes.small = sizes1.small + sizes2.small;
    sizes.medium = sizes1.medium + sizes2.medium;
    sizes.large = sizes1.large + sizes2.large;
    sizes.original = sizes1.original + sizes2.original;

    return sizes;
}

NSString* MXKFileSizes_description(MXKFileSizes sizes)
{
    return [NSString stringWithFormat:@"small: %tu - medium: %tu - large: %tu - original: %tu", sizes.small, sizes.medium, sizes.large, sizes.original];
}

- (void)availableCompressionSizesForAsset:(PHAsset*)asset onComplete:(void(^)(MXKFileSizes sizes))onComplete
{
    __block MXKFileSizes sizes;
    MXKFileSizes_init(&sizes);

    if (asset.mediaType == PHAssetMediaTypeImage)
    {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            
            if (imageData)
            {
                MXLogDebug(@"[MXKRoomInputToolbarView] availableCompressionSizesForAsset: Got image data");
                
                UIImage *image = [UIImage imageWithData:imageData];
                
                MXKImageCompressionSizes compressionSizes = [MXKTools availableCompressionSizesForImage:image originalFileSize:imageData.length];
                
                sizes.small = compressionSizes.small.fileSize;
                sizes.medium = compressionSizes.medium.fileSize;
                sizes.large = compressionSizes.large.fileSize;
                sizes.original = compressionSizes.original.fileSize;
                
                onComplete(sizes);
            }
            else
            {
                MXLogDebug(@"[MXKRoomInputToolbarView] availableCompressionSizesForAsset: Failed to get image data");
                
                // Notify user
                NSError *error = info[@"PHImageErrorKey"];
                if (error.userInfo[NSUnderlyingErrorKey])
                {
                    error = error.userInfo[NSUnderlyingErrorKey];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                
                onComplete(sizes);
            }
            
        }];
    }
    else if (asset.mediaType == PHAssetMediaTypeVideo)
    {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
            
            if ([asset isKindOfClass:[AVURLAsset class]])
            {
                MXLogDebug(@"[MXKRoomInputToolbarView] availableCompressionSizesForAsset: Got video data");
                AVURLAsset* urlAsset = (AVURLAsset*)asset;

                NSNumber *size;
                [urlAsset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];

                sizes.original = size.unsignedIntegerValue;
                sizes.small = sizes.original;
                sizes.medium = sizes.original;
                sizes.large = sizes.original;

                dispatch_async(dispatch_get_main_queue(), ^{
                    onComplete(sizes);
                });
            }
            else
            {
                MXLogDebug(@"[MXKRoomInputToolbarView] availableCompressionSizesForAsset: Failed to get video data");
                
                // Notify user
                NSError *error = info[@"PHImageErrorKey"];
                if (error.userInfo[NSUnderlyingErrorKey])
                {
                    error = error.userInfo[NSUnderlyingErrorKey];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                    onComplete(sizes);
                    
                });
            }
            
        }];
    }
    else
    {
        MXLogDebug(@"[MXKRoomInputToolbarView] availableCompressionSizesForAsset: unexpected media type");
        onComplete(sizes);
    }
}


- (void)availableCompressionSizesForAssets:(NSMutableArray<PHAsset*>*)checkedAssets index:(NSUInteger)index appendTo:(MXKFileSizes)sizes onComplete:(void(^)(NSArray<PHAsset*>*checkedAssets, MXKFileSizes fileSizes))onComplete
{
    [self availableCompressionSizesForAsset:checkedAssets[index] onComplete:^(MXKFileSizes assetSizes) {
        
        MXKFileSizes intermediateSizes;
        NSUInteger nextIndex;
        
        if (assetSizes.original == 0)
        {
            // Ignore this asset
            [checkedAssets removeObjectAtIndex:index];
            intermediateSizes = sizes;
            nextIndex = index;
        }
        else
        {
            intermediateSizes = MXKFileSizes_add(sizes, assetSizes);
            nextIndex = index + 1;
        }

        if (nextIndex == checkedAssets.count)
        {
            // Filter the sizes that are similar
            if (intermediateSizes.medium >= intermediateSizes.large || intermediateSizes.large >= intermediateSizes.original)
            {
                intermediateSizes.large = 0;
            }
            if (intermediateSizes.small >= intermediateSizes.medium || intermediateSizes.medium >= intermediateSizes.original)
            {
                intermediateSizes.medium = 0;
            }
            if (intermediateSizes.small >= intermediateSizes.original)
            {
                intermediateSizes.small = 0;
            }

            onComplete(checkedAssets, intermediateSizes);
        }
        else
        {
            [self availableCompressionSizesForAssets:checkedAssets index:nextIndex appendTo:intermediateSizes onComplete:onComplete];
        }
    }];
}

- (void)availableCompressionSizesForAssets:(NSArray<PHAsset*>*)assets onComplete:(void(^)(NSArray<PHAsset*>*checkedAssets, MXKFileSizes fileSizes))onComplete
{
    __block MXKFileSizes sizes;
    MXKFileSizes_init(&sizes);
    
    NSMutableArray<PHAsset*> *checkedAssets = [NSMutableArray arrayWithArray:assets];

    [self availableCompressionSizesForAssets:checkedAssets index:0 appendTo:sizes onComplete:onComplete];
}

#pragma mark - Attachment handling

- (void)sendSelectedImage:(NSData*)imageData withMimeType:(NSString *)mimetype andCompressionMode:(MXKRoomInputToolbarCompressionMode)compressionMode isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset
{
    // Check condition before saving this media in user's library
    if (_enableAutoSaving && !isPhotoLibraryAsset)
    {
        // Save the original image in user's photos library
        UIImage *image = [UIImage imageWithData:imageData];
        [MXMediaManager saveImageToPhotosLibrary:image success:nil failure:nil];
    }

    // Send data without compression if the image type is not jpeg
    // Force compression for a heic image so that we generate jpeg from it
    if (mimetype
        && [mimetype isEqualToString:@"image/jpeg"] == NO
        && [mimetype isEqualToString:@"image/heic"] == NO
        && [self.delegate respondsToSelector:@selector(roomInputToolbarView:sendImage:withMimeType:)])
    {
        [self.delegate roomInputToolbarView:self sendImage:imageData withMimeType:mimetype];
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:sendImage:)])
        {
            [self sendImage:imageData withCompressionMode:compressionMode];
        }
        else
        {
            MXLogDebug(@"[MXKRoomInputToolbarView] Attach image is not supported");
        }
    }
}

- (void)sendImage:(NSData*)imageData withCompressionMode:(MXKRoomInputToolbarCompressionMode)compressionMode
{
    if (optionsListView)
    {
        [optionsListView dismissViewControllerAnimated:NO completion:nil];
        optionsListView = nil;
    }
    
    if (compressionPrompt && compressionMode == MXKRoomInputToolbarCompressionModePrompt)
    {
        // Delay the image sending
        if (!pendingImages)
        {
            pendingImages = [NSMutableArray arrayWithObject:imageData];
        }
        else
        {
            [pendingImages addObject:imageData];
        }
        return;
    }

    // Get available sizes for this image
    UIImage *image = [UIImage imageWithData:imageData];
    MXKImageCompressionSizes compressionSizes = [MXKTools availableCompressionSizesForImage:image originalFileSize:imageData.length];

    // Apply the compression mode
    if (compressionMode == MXKRoomInputToolbarCompressionModePrompt
        && (compressionSizes.small.fileSize || compressionSizes.medium.fileSize || compressionSizes.large.fileSize))
    {
        __weak typeof(self) weakSelf = self;
        
        compressionPrompt = [UIAlertController alertControllerWithTitle:[VectorL10n attachmentSizePromptTitle]
                                                                message:[VectorL10n attachmentSizePromptMessage]
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
        
        if (compressionSizes.small.fileSize)
        {
            NSString *fileSizeString = [MXTools fileSizeToString:compressionSizes.small.fileSize];

            NSString *title = [VectorL10n attachmentSmall:fileSizeString];
            
            [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    if (weakSelf)
                                                                    {
                                                                        typeof(self) self = weakSelf;
                                                                        
                                                                        // Send the small image
                                                                        UIImage *smallImage = [MXKTools reduceImage:image toFitInSize:CGSizeMake(MXKTOOLS_SMALL_IMAGE_SIZE, MXKTOOLS_SMALL_IMAGE_SIZE)];
                                                                        [self.delegate roomInputToolbarView:self sendImage:smallImage];
                                                                        
                                                                        [self dismissCompressionPrompt];
                                                                    }
                                                                    
                                                                }]];
        }
        
        if (compressionSizes.medium.fileSize)
        {
            NSString *fileSizeString = [MXTools fileSizeToString:compressionSizes.medium.fileSize];

            NSString *title = [VectorL10n attachmentMedium:fileSizeString];
            
            [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    if (weakSelf)
                                                                    {
                                                                        typeof(self) self = weakSelf;
                                                                        
                                                                        // Send the medium image
                                                                        UIImage *mediumImage = [MXKTools reduceImage:image toFitInSize:CGSizeMake(MXKTOOLS_MEDIUM_IMAGE_SIZE, MXKTOOLS_MEDIUM_IMAGE_SIZE)];
                                                                        [self.delegate roomInputToolbarView:self sendImage:mediumImage];
                                                                        
                                                                        [self dismissCompressionPrompt];
                                                                    }
                                                                    
                                                                }]];
        }
        
        if (compressionSizes.large.fileSize)
        {
            NSString *fileSizeString = [MXTools fileSizeToString:compressionSizes.large.fileSize];

            NSString *title = [VectorL10n attachmentLarge:fileSizeString];
            
            [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    if (weakSelf)
                                                                    {
                                                                        typeof(self) self = weakSelf;
                                                                        
                                                                        // Send the large image
                                                                        UIImage *largeImage = [MXKTools reduceImage:image toFitInSize:CGSizeMake(compressionSizes.actualLargeSize, compressionSizes.actualLargeSize)];
                                                                        [self.delegate roomInputToolbarView:self sendImage:largeImage];
                                                                        
                                                                        [self dismissCompressionPrompt];
                                                                    }
                                                                    
                                                                }]];
        }
        
        NSString *fileSizeString = [MXTools fileSizeToString:compressionSizes.original.fileSize];
        
        NSString *title = [VectorL10n attachmentOriginal:fileSizeString];
        
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                if (weakSelf)
                                                                {
                                                                    typeof(self) self = weakSelf;
                                                                    
                                                                    // Send the original image
                                                                    [self.delegate roomInputToolbarView:self sendImage:image];
                                                                    
                                                                    [self dismissCompressionPrompt];
                                                                }
                                                                
                                                            }]];
        
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                if (weakSelf)
                                                                {
                                                                    typeof(self) self = weakSelf;
                                                                    
                                                                    [self dismissCompressionPrompt];
                                                                }
                                                                
                                                            }]];
        
        [compressionPrompt popoverPresentationController].sourceView = self;
        [compressionPrompt popoverPresentationController].sourceRect = self.bounds;
        [self.delegate roomInputToolbarView:self presentAlertController:compressionPrompt];
    }
    else
    {
        // By default the original image is sent
        UIImage *finalImage = image;
        
        switch (compressionMode)
        {
            case MXKRoomInputToolbarCompressionModePrompt:
                // Here the image size is too small to need compression - send the original image
                break;
                
            case MXKRoomInputToolbarCompressionModeSmall:
                if (compressionSizes.small.fileSize)
                {
                    finalImage = [MXKTools reduceImage:image toFitInSize:CGSizeMake(MXKTOOLS_SMALL_IMAGE_SIZE, MXKTOOLS_SMALL_IMAGE_SIZE)];
                }
                break;
                
            case MXKRoomInputToolbarCompressionModeMedium:
                if (compressionSizes.medium.fileSize)
                {
                    finalImage = [MXKTools reduceImage:image toFitInSize:CGSizeMake(MXKTOOLS_MEDIUM_IMAGE_SIZE, MXKTOOLS_MEDIUM_IMAGE_SIZE)];
                }
                break;
                
            case MXKRoomInputToolbarCompressionModeLarge:
                if (compressionSizes.large.fileSize)
                {
                    finalImage = [MXKTools reduceImage:image toFitInSize:CGSizeMake(compressionSizes.actualLargeSize, compressionSizes.actualLargeSize)];
                }
                break;
                
            default:
                // no compression, send original
                break;
        }
        
        // Send the image
        [self.delegate roomInputToolbarView:self sendImage:finalImage];
    }
}

- (void)sendSelectedVideo:(NSURL*)selectedVideo isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset
{
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:selectedVideo];
    [self sendSelectedVideoAsset:videoAsset isPhotoLibraryAsset:isPhotoLibraryAsset];
}

- (void)sendSelectedVideoAsset:(AVAsset*)selectedVideo isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset
{
    // Check condition before saving this media in user's library
    if (_enableAutoSaving && !isPhotoLibraryAsset)
    {
        if ([selectedVideo isKindOfClass:[AVURLAsset class]])
        {
            AVURLAsset *urlAsset = (AVURLAsset*)selectedVideo;
            [MXMediaManager saveMediaToPhotosLibrary:[urlAsset URL] isImage:NO success:nil failure:nil];
        }
        else
        {
            MXLogError(@"[RoomInputToolbarView] Unable to save video, incorrect asset type.")
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:sendVideoAsset:withThumbnail:)])
    {
        // Retrieve the video frame at 1 sec to define the video thumbnail
        AVAssetImageGenerator *assetImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:selectedVideo];
        assetImageGenerator.appliesPreferredTrackTransform = YES;
        CMTime time = CMTimeMake(1, 1);
        CGImageRef imageRef = [assetImageGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
        
        // Finalize video attachment
        UIImage* videoThumbnail = [[UIImage alloc] initWithCGImage:imageRef];
        CFRelease(imageRef);
        
        [self.delegate roomInputToolbarView:self sendVideoAsset:selectedVideo withThumbnail:videoThumbnail];
    }
    else
    {
        MXLogDebug(@"[RoomInputToolbarView] Attach video is not supported");
    }
}

- (void)sendSelectedAssets:(NSArray<PHAsset*>*)assets withCompressionMode:(MXKRoomInputToolbarCompressionMode)compressionMode
{
    // Get data about the selected assets
    if (assets.count)
    {
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:updateActivityIndicator:)])
        {
            [self.delegate roomInputToolbarView:self updateActivityIndicator:YES];
        }
        
        [self availableCompressionSizesForAssets:assets onComplete:^(NSArray<PHAsset*>*checkedAssets, MXKFileSizes fileSizes) {
            
            if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:updateActivityIndicator:)])
            {
                [self.delegate roomInputToolbarView:self updateActivityIndicator:NO];
            }
            
            if (checkedAssets.count)
            {
                [self sendSelectedAssets:checkedAssets withFileSizes:fileSizes andCompressionMode:compressionMode];
            }
            
        }];
    }
}

- (void)sendSelectedAssets:(NSArray<PHAsset*>*)assets withFileSizes:(MXKFileSizes)fileSizes andCompressionMode:(MXKRoomInputToolbarCompressionMode)compressionMode
{
    if (compressionMode == MXKRoomInputToolbarCompressionModePrompt
        && (fileSizes.small || fileSizes.medium || fileSizes.large))
    {
        // Ask the user for the compression value
        compressionPrompt = [UIAlertController alertControllerWithTitle:[VectorL10n attachmentSizePromptTitle]
                                                                message:[VectorL10n attachmentSizePromptMessage]
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
        
        __weak typeof(self) weakSelf = self;

        if (fileSizes.small)
        {
            NSString *title = [VectorL10n attachmentSmall:[MXTools fileSizeToString:fileSizes.small]];
            
            [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    if (weakSelf)
                                                                    {
                                                                        typeof(self) self = weakSelf;
                                                                        
                                                                        [self dismissCompressionPrompt];
                                                                        
                                                                        [self sendSelectedAssets:assets withFileSizes:fileSizes andCompressionMode:MXKRoomInputToolbarCompressionModeSmall];
                                                                    }
                                                                    
                                                                }]];
        }

        if (fileSizes.medium)
        {
            NSString *title = [VectorL10n attachmentMedium:[MXTools fileSizeToString:fileSizes.medium]];
            
            [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    if (weakSelf)
                                                                    {
                                                                        typeof(self) self = weakSelf;
                                                                        
                                                                        [self dismissCompressionPrompt];
                                                                        
                                                                        [self sendSelectedAssets:assets withFileSizes:fileSizes andCompressionMode:MXKRoomInputToolbarCompressionModeMedium];
                                                                    }
                                                                    
                                                                }]];
        }

        if (fileSizes.large)
        {
            NSString *title = [VectorL10n attachmentLarge:[MXTools fileSizeToString:fileSizes.large]];
            
            [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    
                                                                    if (weakSelf)
                                                                    {
                                                                        typeof(self) self = weakSelf;
                                                                        
                                                                        [self dismissCompressionPrompt];
                                                                        
                                                                        [self sendSelectedAssets:assets withFileSizes:fileSizes andCompressionMode:MXKRoomInputToolbarCompressionModeLarge];
                                                                    }
                                                                    
                                                                }]];
        }

        NSString *title = [VectorL10n attachmentOriginal:[MXTools fileSizeToString:fileSizes.original]];
        
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:title
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                if (weakSelf)
                                                                {
                                                                    typeof(self) self = weakSelf;
                                                                    
                                                                    [self dismissCompressionPrompt];
                                                                    
                                                                    [self sendSelectedAssets:assets withFileSizes:fileSizes andCompressionMode:MXKRoomInputToolbarCompressionModeNone];
                                                                }
                                                                
                                                            }]];
        
        [compressionPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction * action) {
                                                                
                                                                if (weakSelf)
                                                                {
                                                                    typeof(self) self = weakSelf;
                                                                    
                                                                    [self dismissCompressionPrompt];
                                                                }
                                                                
                                                            }]];
        
        [compressionPrompt popoverPresentationController].sourceView = self;
        [compressionPrompt popoverPresentationController].sourceRect = self.bounds;
        [self.delegate roomInputToolbarView:self presentAlertController:compressionPrompt];
    }
    else
    {
        // Send all media with the selected compression mode
        for (PHAsset *asset in assets)
        {
            if (asset.mediaType == PHAssetMediaTypeImage)
            {
                // Retrieve the full sized image data
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.synchronous = NO;
                options.networkAccessAllowed = YES;
                
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    
                    if (imageData)
                    {
                        MXLogDebug(@"[MXKRoomInputToolbarView] sendSelectedAssets: Got image data");
                        
                        CFStringRef uti = (__bridge CFStringRef)dataUTI;
                        NSString *mimeType = (__bridge_transfer NSString *) UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
                        
                        [self sendSelectedImage:imageData withMimeType:mimeType andCompressionMode:compressionMode isPhotoLibraryAsset:YES];
                    }
                    else
                    {
                        MXLogDebug(@"[MXKRoomInputToolbarView] sendSelectedAssets: Failed to get image data");
                        
                        // Notify user
                        NSError *error = info[@"PHImageErrorKey"];
                        if (error.userInfo[NSUnderlyingErrorKey])
                        {
                            error = error.userInfo[NSUnderlyingErrorKey];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                    }
                    
                }];
            }
            else if (asset.mediaType == PHAssetMediaTypeVideo)
            {
                PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
                options.networkAccessAllowed = YES;
                
                [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
                    
                    if ([asset isKindOfClass:[AVURLAsset class]])
                    {
                        MXLogDebug(@"[MXKRoomInputToolbarView] sendSelectedAssets: Got video data");
                        AVURLAsset* urlAsset = (AVURLAsset*)asset;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self sendSelectedVideo:urlAsset.URL isPhotoLibraryAsset:YES];
                            
                        });
                    }
                    else
                    {
                        MXLogDebug(@"[MXKRoomInputToolbarView] sendSelectedAssets: Failed to get video data");
                        
                        // Notify user
                        NSError *error = info[@"PHImageErrorKey"];
                        if (error.userInfo[NSUnderlyingErrorKey])
                        {
                            error = error.userInfo[NSUnderlyingErrorKey];
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                            
                        });
                    }
                    
                }];
            }
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissMediaPicker];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage])
    {
        UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (selectedImage)
        {
            // Media picker does not offer a preview
            // so add a preview to let the user validates his selection
            if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
            {
                __weak typeof(self) weakSelf = self;
                
                MXKImageView *imageValidationView = [[MXKImageView alloc] initWithFrame:CGRectZero];
                imageValidationView.stretchable = YES;
                
                // the user validates the image
                [imageValidationView setRightButtonTitle:[VectorL10n ok] handler:^(MXKImageView* imageView, NSString* buttonTitle)
                 {
                     if (weakSelf)
                     {
                         typeof(self) self = weakSelf;
                         
                         // Dismiss the image view
                         [self dismissValidationViews];
                         
                         NSURL *imageLocalURL = [info objectForKey:UIImagePickerControllerReferenceURL];
                         if (imageLocalURL)
                         {
                             CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[imageLocalURL.path pathExtension] , NULL);
                             NSString *mimetype = (__bridge_transfer NSString *) UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
                             CFRelease(uti);
                             
                             NSData *imageData = [NSData dataWithContentsOfFile:imageLocalURL.path];
                             
                             // attach the selected image
                             [self sendSelectedImage:imageData withMimeType:mimetype andCompressionMode:MXKRoomInputToolbarCompressionModePrompt isPhotoLibraryAsset:YES];
                         }
                     }
                     
                 }];
                
                // the user wants to use an other image
                [imageValidationView setLeftButtonTitle:[VectorL10n cancel] handler:^(MXKImageView* imageView, NSString* buttonTitle)
                 {
                     if (weakSelf)
                     {
                         typeof(self) self = weakSelf;
                         
                         // dismiss the image view
                         [self dismissValidationViews];
                         
                         // Open again media gallery
                         self->mediaPicker = [[UIImagePickerController alloc] init];
                         self->mediaPicker.delegate = self;
                         self->mediaPicker.sourceType = picker.sourceType;
                         self->mediaPicker.allowsEditing = NO;
                         self->mediaPicker.mediaTypes = picker.mediaTypes;
                         [self.delegate roomInputToolbarView:self presentViewController:self->mediaPicker];
                     }
                 }];
                
                imageValidationView.image = selectedImage;
                
                [validationViews addObject:imageValidationView];
                [imageValidationView showFullScreen];
                [self.delegate roomInputToolbarView:self hideStatusBar:YES];
            }
            else
            {
                // Suggest compression before sending image
                NSData *imageData = UIImageJPEGRepresentation(selectedImage, 0.9);
                [self sendSelectedImage:imageData withMimeType:nil andCompressionMode:MXKRoomInputToolbarCompressionModePrompt isPhotoLibraryAsset:NO];
            }
        }
    }
    else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie])
    {
        NSURL* selectedVideo = [info objectForKey:UIImagePickerControllerMediaURL];
        
        [self sendSelectedVideo:selectedVideo isPhotoLibraryAsset:(picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissMediaPicker];
}

- (void)dismissValidationViews
{
    if (validationViews.count)
    {
        for (MXKImageView *validationView in validationViews)
        {
            [validationView dismissSelection];
            [validationView removeFromSuperview];
        }
        
        [validationViews removeAllObjects];
        
        // Restore status bar
        [self.delegate roomInputToolbarView:self hideStatusBar:NO];
    }
}

- (void)dismissValidationView:(MXKImageView*)validationView
{
    [validationView dismissSelection];
    [validationView removeFromSuperview];
    
    if (validationViews.count)
    {
        [validationViews removeObject:validationView];
        
        if (!validationViews.count)
        {
            // Restore status bar
            [self.delegate roomInputToolbarView:self hideStatusBar:NO];
        }
    }
}

- (void)dismissMediaPicker
{
    if (mediaPicker)
    {
        mediaPicker.delegate = nil;
        
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:dismissViewControllerAnimated:completion:)])
        {
            [self.delegate roomInputToolbarView:self dismissViewControllerAnimated:NO completion:^{
                self->mediaPicker = nil;
            }];
        }
    }
}

#pragma mark - Clipboard - Handle image/data paste from general pasteboard

- (void)paste:(id)sender
{
    UIPasteboard *pasteboard = MXKPasteboardManager.shared.pasteboard;
    if (pasteboard.numberOfItems)
    {
        [self dismissValidationViews];
        [self dismissKeyboard];
        
        __weak typeof(self) weakSelf = self;
        
        for (NSDictionary* dict in pasteboard.items)
        {
            NSArray* allKeys = dict.allKeys;
            for (NSString* key in allKeys)
            {
                NSString* MIMEType = (__bridge_transfer NSString *) UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)key, kUTTagClassMIMEType);
                if ([MIMEType hasPrefix:@"image/"] && [self.delegate respondsToSelector:@selector(roomInputToolbarView:sendImage:)])
                {
                    UIImage *pasteboardImage;
                    if ([[dict objectForKey:key] isKindOfClass:UIImage.class])
                    {
                        pasteboardImage = [dict objectForKey:key];
                    }
                    // WebP images from Safari appear on the pasteboard as NSData rather than UIImages.
                    else if ([[dict objectForKey:key] isKindOfClass:NSData.class])
                    {
                        pasteboardImage = [UIImage imageWithData:[dict objectForKey:key]];
                    }
                    else {
                        NSString *message = [NSString stringWithFormat:@"[MXKRoomInputToolbarView] Unsupported image format %@ for mimetype %@ pasted.", MIMEType, NSStringFromClass([[dict objectForKey:key] class])];
                        MXLogError(message);
                    }
                    
                    if (pasteboardImage)
                    {
                        MXKImageView *imageValidationView = [[MXKImageView alloc] initWithFrame:CGRectZero];
                        imageValidationView.stretchable = YES;
                        
                        // the user validates the image
                        [imageValidationView setRightButtonTitle:[VectorL10n ok] handler:^(MXKImageView* imageView, NSString* buttonTitle)
                         {
                             if (weakSelf)
                             {
                                 typeof(self) self = weakSelf;
                                 [self dismissValidationView:imageView];
                                 [self.delegate roomInputToolbarView:self sendImage:pasteboardImage];
                             }
                         }];
                        
                        // the user wants to use an other image
                        [imageValidationView setLeftButtonTitle:[VectorL10n cancel] handler:^(MXKImageView* imageView, NSString* buttonTitle)
                         {
                             // Dismiss the image validation view.
                             if (weakSelf)
                             {
                                 typeof(self) self = weakSelf;
                                 [self dismissValidationView:imageView];
                             }
                         }];
                        
                        imageValidationView.image = pasteboardImage;
                        
                        [validationViews addObject:imageValidationView];
                        [imageValidationView showFullScreen];
                        [self.delegate roomInputToolbarView:self hideStatusBar:YES];
                    }
                    
                    break;
                }
                else if ([MIMEType hasPrefix:@"video/"] && [self.delegate respondsToSelector:@selector(roomInputToolbarView:sendVideo:withThumbnail:)])
                {
                    NSData *pasteboardVideoData = [dict objectForKey:key];
                    // Get a unique cache path to store this video
                    NSString *cacheFilePath = [MXMediaManager temporaryCachePathInFolder:nil withType:MIMEType];
                    
                    if ([MXMediaManager writeMediaData:pasteboardVideoData toFilePath:cacheFilePath])
                    {
                        NSURL *videoLocalURL = [NSURL fileURLWithPath:cacheFilePath isDirectory:NO];
                        
                        // Retrieve the video frame at 1 sec to define the video thumbnail
                        AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:videoLocalURL options:nil];
                        AVAssetImageGenerator *assetImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
                        assetImageGenerator.appliesPreferredTrackTransform = YES;
                        CMTime time = CMTimeMake(1, 1);
                        CGImageRef imageRef = [assetImageGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
                        UIImage* videoThumbnail = [[UIImage alloc] initWithCGImage:imageRef];
                        CFRelease (imageRef);
                        
                        MXKImageView *videoValidationView = [[MXKImageView alloc] initWithFrame:CGRectZero];
                        videoValidationView.stretchable = YES;
                        
                        // the user validates the image
                        [videoValidationView setRightButtonTitle:[VectorL10n ok] handler:^(MXKImageView* imageView, NSString* buttonTitle)
                         {
                             if (weakSelf)
                             {
                                 typeof(self) self = weakSelf;
                                 [self dismissValidationView:imageView];
                                 
                                 [self.delegate roomInputToolbarView:self sendVideo:videoLocalURL withThumbnail:videoThumbnail];
                             }
                         }];
                        
                        // the user wants to use an other image
                        [videoValidationView setLeftButtonTitle:[VectorL10n cancel] handler:^(MXKImageView* imageView, NSString* buttonTitle)
                         {
                             // Dismiss the video validation view.
                             if (weakSelf)
                             {
                                 typeof(self) self = weakSelf;
                                 [self dismissValidationView:imageView];
                             }
                         }];
                        
                        videoValidationView.image = videoThumbnail;
                        
                        [validationViews addObject:videoValidationView];
                        [videoValidationView showFullScreen];
                        [self.delegate roomInputToolbarView:self hideStatusBar:YES];
                        
                        // Add video icon
                        UIImageView *videoIconView = [[UIImageView alloc] initWithImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_video"]];
                        videoIconView.center = videoValidationView.center;
                        videoIconView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
                        [videoValidationView addSubview:videoIconView];
                    }
                    break;
                }
                else if ([MIMEType hasPrefix:@"application/"] && [self.delegate respondsToSelector:@selector(roomInputToolbarView:sendFile:withMimeType:)])
                {
                    NSData *pasteboardDocumentData = [dict objectForKey:key];
                    // Get a unique cache path to store this data
                    NSString *cacheFilePath = [MXMediaManager temporaryCachePathInFolder:nil withType:MIMEType];
                    
                    if ([MXMediaManager writeMediaData:pasteboardDocumentData toFilePath:cacheFilePath])
                    {
                        NSURL *localURL = [NSURL fileURLWithPath:cacheFilePath isDirectory:NO];
                        
                        MXKImageView *docValidationView = [[MXKImageView alloc] initWithFrame:CGRectZero];
                        docValidationView.stretchable = YES;
                        
                        // the user validates the image
                        [docValidationView setRightButtonTitle:[VectorL10n ok] handler:^(MXKImageView* imageView, NSString* buttonTitle)
                         {
                             if (weakSelf)
                             {
                                 typeof(self) self = weakSelf;
                                 [self dismissValidationView:imageView];
                                 
                                 [self.delegate roomInputToolbarView:self sendFile:localURL withMimeType:MIMEType];
                             }
                         }];
                        
                        // the user wants to use an other image
                        [docValidationView setLeftButtonTitle:[VectorL10n cancel] handler:^(MXKImageView* imageView, NSString* buttonTitle)
                         {
                             // Dismiss the validation view.
                             if (weakSelf)
                             {
                                 typeof(self) self = weakSelf;
                                 [self dismissValidationView:imageView];
                             }
                         }];
                        
                        docValidationView.image = nil;
                        
                        [validationViews addObject:docValidationView];
                        [docValidationView showFullScreen];
                        [self.delegate roomInputToolbarView:self hideStatusBar:YES];
                        
                        // Create a fake name based on fileData to keep the same name for the same file.
                        NSString *dataHash = [pasteboardDocumentData mx_MD5];
                        if (dataHash.length > 7)
                        {
                            // Crop
                            dataHash = [dataHash substringToIndex:7];
                        }
                        NSString *extension = [MXTools fileExtensionFromContentType:MIMEType];
                        NSString *filename = [NSString stringWithFormat:@"file_%@%@", dataHash, extension];
                        
                        // Display this file name
                        UITextView *fileNameTextView = [[UITextView alloc] initWithFrame:CGRectZero];
                        fileNameTextView.text = filename;
                        fileNameTextView.font = [UIFont systemFontOfSize:17];
                        [fileNameTextView sizeToFit];
                        fileNameTextView.center = docValidationView.center;
                        fileNameTextView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
                        
                        docValidationView.backgroundColor = [UIColor whiteColor];
                        [docValidationView addSubview:fileNameTextView];
                    }
                    break;
                }
            }
        }
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:) && MXKAppSettings.standardAppSettings.messageDetailsAllowPastingMedia)
    {
        // Check whether some data listed in general pasteboard can be paste
        UIPasteboard *pasteboard = MXKPasteboardManager.shared.pasteboard;
        if (pasteboard.numberOfItems)
        {
            for (NSArray<NSString *> *types in [pasteboard pasteboardTypesForItemSet:nil])
            {
                for (NSString *type in types)
                {
                    NSString* MIMEType = (__bridge_transfer NSString *) UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)type, kUTTagClassMIMEType);
                    
                    if ([MIMEType hasPrefix:@"image/"] && [self.delegate respondsToSelector:@selector(roomInputToolbarView:sendImage:)])
                    {
                        return YES;
                    }
                    
                    if ([MIMEType hasPrefix:@"video/"] && [self.delegate respondsToSelector:@selector(roomInputToolbarView:sendVideo:withThumbnail:)])
                    {
                        return YES;
                    }
                    
                    if ([MIMEType hasPrefix:@"application/"] && [self.delegate respondsToSelector:@selector(roomInputToolbarView:sendFile:withMimeType:)])
                    {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

@end
