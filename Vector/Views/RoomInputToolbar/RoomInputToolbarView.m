/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "RoomInputToolbarView.h"

//#import <MediaPlayer/MediaPlayer.h>
//#import <MobileCoreServices/MobileCoreServices.h>
//
//#import <AssetsLibrary/ALAsset.h>
//#import <AssetsLibrary/ALAssetRepresentation.h>

#define MXKROOM_INPUT_TOOLBAR_VIEW_LARGE_IMAGE_SIZE    1024
#define MXKROOM_INPUT_TOOLBAR_VIEW_MEDIUM_IMAGE_SIZE   768
#define MXKROOM_INPUT_TOOLBAR_VIEW_SMALL_IMAGE_SIZE    512

@interface RoomInputToolbarView()
{
    /**
     The current height of the toolbar.
     */
    CGFloat actualToolBarHeight;
    
    MediaPickerViewController *mediaPicker;
}

@end

@implementation RoomInputToolbarView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomInputToolbarView class])
                          bundle:[NSBundle bundleForClass:[RoomInputToolbarView class]]];
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
    
    // Remove default toolbar background color
    self.backgroundColor = [UIColor whiteColor];
    
    self.startVoiceCallLabel.text = NSLocalizedStringFromTable(@"room_option_start_group_voice", @"Vector", nil);
    self.startVoiceCallLabel.numberOfLines = 0;
    self.startVideoCallLabel.text = NSLocalizedStringFromTable(@"room_option_start_group_video", @"Vector", nil);
    self.startVideoCallLabel.numberOfLines = 0;
    self.shareLocationLabel.text = NSLocalizedStringFromTable(@"room_option_share_location", @"Vector", nil);
    self.shareLocationLabel.numberOfLines = 0;
    self.shareContactLabel.text = NSLocalizedStringFromTable(@"room_option_share_contact", @"Vector", nil);
    self.shareContactLabel.numberOfLines = 0;
    
    actualToolBarHeight = self.frame.size.height;
}

#pragma mark - HPGrowingTextView delegate

- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)growingTextView
{
    // The return sends the message rather than giving a carriage return.
    [self onTouchUpInside:self.rightInputToolbarButton];
    
    return NO;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    // Clean the carriage return added on return press
    if ([self.textMessage isEqualToString:@"\n"])
    {
        self.textMessage = nil;
    }
    
    [super growingTextViewDidChange:growingTextView];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    actualToolBarHeight = height + (self.messageComposerContainerTopConstraint.constant + self.messageComposerContainerBottomConstraint.constant);
    
    [super growingTextView:growingTextView willChangeHeight:height];
}

#pragma mark - Override MXKRoomInputToolbarView

- (IBAction)onTouchUpInside:(UIButton*)button
{
    if (button == self.attachMediaButton)
    {
        // Check whether media attachment is supported
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:presentViewController:)])
        {
            mediaPicker = [MediaPickerViewController mediaPickerViewController];
            mediaPicker.delegate = self;
            UINavigationController *navigationController = [UINavigationController new];
            [navigationController pushViewController:mediaPicker animated:NO];
            
            [self.delegate roomInputToolbarView:self presentViewController:navigationController];
        }
        else
        {
            NSLog(@"[RoomInputToolbarView] Attach media is not supported");
        }
    }
    else if (button == self.optionMenuButton)
    {
        if (self.optionMenuView.isHidden)
        {
            actualToolBarHeight += self.optionMenuView.frame.size.height;
            self.messageComposerContainerTopConstraint.constant += self.optionMenuView.frame.size.height;
        }
        else
        {
            actualToolBarHeight -= self.optionMenuView.frame.size.height;
            self.messageComposerContainerTopConstraint.constant -= self.optionMenuView.frame.size.height;
        }
        
        // Update toolbar superview
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:heightDidChanged:)])
        {
            [self.delegate roomInputToolbarView:self heightDidChanged:actualToolBarHeight];
        }
        
        // Refresh max height of the growning text
        self.maxHeight = self.maxHeight;
        
        self.optionMenuView.hidden = !self.optionMenuView.isHidden;
    }
    else if (button == self.startVoiceCallButton)
    {
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:placeCallWithVideo:)])
        {
            [self.delegate roomInputToolbarView:self placeCallWithVideo:NO];
        }
    }
    else if (button == self.startVideoCallButton)
    {
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:placeCallWithVideo:)])
        {
            [self.delegate roomInputToolbarView:self placeCallWithVideo:YES];
        }
    }
    else if (button == self.shareLocationButton)
    {
        // TODO
    }
    else if (button == self.shareContactButton)
    {
        // TODO
    }
    
    [super onTouchUpInside:button];
}


- (void)destroy
{
    [super destroy];
}

//#pragma mark - UIImagePickerControllerDelegate
//
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//{
//    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
//    if ([mediaType isEqualToString:(NSString *)kUTTypeImage])
//    {
//        
//        /*
//         NSData *dataOfGif = [NSData dataWithContentsOfFile: [info objectForKey:UIImagePickerControllerReferenceURL]];
//         
//         NSLog(@"%d", dataOfGif.length);
//         
//         ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//         [library assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset)
//         {
//         
//         NSLog(@"%@", asset.defaultRepresentation.metadata);
//         
//         
//         NSLog(@"%@", asset.defaultRepresentation.url);
//         
//         NSData *dataOfGif = [NSData dataWithContentsOfURL: asset.defaultRepresentation.url];
//         
//         NSLog(@"%d", dataOfGif.length);
//         ;
//         
//         } failureBlock:^(NSError *error)
//         {
//         
//         }];
//         
//         */
//        
//        if (![self.delegate respondsToSelector:@selector(roomInputToolbarView:sendImage:)])
//        {
//            NSLog(@"[RoomInputToolbarView] Attach image is not supported");
//        }
//        else
//        {
//            UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
//            if (selectedImage)
//            {
//                // media picker does not offer a preview
//                // so add a preview to let the user validates his selection
//                if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
//                {
//                    __weak typeof(self) weakSelf = self;
//                    
//                    imageValidationView = [[MXKImageView alloc] initWithFrame:CGRectZero];
//                    imageValidationView.stretchable = YES;
//                    
//                    // the user validates the image
//                    [imageValidationView setRightButtonTitle:[NSBundle mxk_localizedStringForKey:@"ok"] handler:^(MXKImageView* imageView, NSString* buttonTitle)
//                    {
//                        __strong __typeof(weakSelf)strongSelf = weakSelf;
//                        
//                        // Dismiss the image view
//                        [strongSelf dismissImageValidationView];
//                       
//                        // prompt user about image compression
//                        [strongSelf promptCompressionForSelectedImage:info];
//                    }];
//                    
//                    // the user wants to use an other image
//                    [imageValidationView setLeftButtonTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] handler:^(MXKImageView* imageView, NSString* buttonTitle)
//                    {
//                        __strong __typeof(weakSelf)strongSelf = weakSelf;
//                        
//                        // dismiss the image view
//                        [strongSelf dismissImageValidationView];
//                        
//                        // Open again media gallery
//                        strongSelf->mediaPicker = [[UIImagePickerController alloc] init];
//                        strongSelf->mediaPicker.delegate = strongSelf;
//                        strongSelf->mediaPicker.sourceType = picker.sourceType;
//                        strongSelf->mediaPicker.allowsEditing = NO;
//                        strongSelf->mediaPicker.mediaTypes = picker.mediaTypes;
//                        [strongSelf.delegate roomInputToolbarView:strongSelf presentMediaPicker:strongSelf->mediaPicker];
//                    }];
//                    
//                    imageValidationView.image = selectedImage;
//                    [imageValidationView showFullScreen];
//                }
//                else
//                {
//                    // Save the original image in user's photos library and suggest compression before sending image
//                    [MXKMediaManager saveImageToPhotosLibrary:selectedImage success:nil failure:nil];
//                    [self promptCompressionForSelectedImage:info];
//                }
//            }
//        }
//    }
//    else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie])
//    {
//        NSURL* selectedVideo = [info objectForKey:UIImagePickerControllerMediaURL];
//        
//        // Check the selected video, and ignore multiple calls (observed when user pressed several time Choose button)
//        if (selectedVideo && !tmpVideoPlayer)
//        {
//            if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
//            {
//                [MXKMediaManager saveMediaToPhotosLibrary:selectedVideo isImage:NO success:nil failure:nil];
//            }
//            
//            // Create video thumbnail
//            tmpVideoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:selectedVideo];
//            if (tmpVideoPlayer)
//            {
//                [tmpVideoPlayer setShouldAutoplay:NO];
//                [[NSNotificationCenter defaultCenter] addObserver:self
//                                                         selector:@selector(moviePlayerThumbnailImageRequestDidFinishNotification:)
//                                                             name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
//                                                           object:nil];
//                [tmpVideoPlayer requestThumbnailImagesAtTimes:@[@1.0f] timeOption:MPMovieTimeOptionNearestKeyFrame];
//                // We will finalize video attachment when thumbnail will be available (see movie player callback)
//                return;
//            }
//        }
//    }
//    
//    [self dismissMediaPicker];
//}
//
//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
//{
//    [self dismissMediaPicker];
//}
//
//- (void)dismissImageValidationView
//{
//    if (imageValidationView)
//    {
//        [imageValidationView dismissSelection];
//        [imageValidationView removeFromSuperview];
//        imageValidationView = nil;
//    }
//}
//
//- (void)promptCompressionForSelectedImage:(NSDictionary*)selectedImageInfo
//{
//    if (currentAlert)
//    {
//        [currentAlert dismiss:NO];
//        currentAlert = nil;
//    }
//    
//    UIImage *selectedImage = [selectedImageInfo objectForKey:UIImagePickerControllerOriginalImage];
//    CGSize originalSize = selectedImage.size;
//    NSLog(@"Selected image size : %f %f", originalSize.width, originalSize.height);
//    
//    [self getSelectedImageFileData:selectedImageInfo success:^(NSData *selectedImageFileData) {
//        
//        long long smallFilesize  = 0;
//        long long mediumFilesize = 0;
//        long long largeFilesize  = 0;
//        
//        // succeed to get the file size (provided by the photo library)
//        long long originalFileSize = selectedImageFileData.length;
//        NSLog(@"- use the photo library file size: %tu", originalFileSize);
//        
//        CGFloat maxSize = MAX(originalSize.width, originalSize.height);
//        if (maxSize >= MXKROOM_INPUT_TOOLBAR_VIEW_SMALL_IMAGE_SIZE)
//        {
//            CGFloat factor = MXKROOM_INPUT_TOOLBAR_VIEW_SMALL_IMAGE_SIZE / maxSize;
//            smallFilesize = factor * factor * originalFileSize;
//        }
//        else
//        {
//            NSLog(@"- too small to fit in %d", MXKROOM_INPUT_TOOLBAR_VIEW_SMALL_IMAGE_SIZE);
//        }
//        
//        if (maxSize >= MXKROOM_INPUT_TOOLBAR_VIEW_MEDIUM_IMAGE_SIZE)
//        {
//            CGFloat factor = MXKROOM_INPUT_TOOLBAR_VIEW_MEDIUM_IMAGE_SIZE / maxSize;
//            mediumFilesize = factor * factor * originalFileSize;
//        }
//        else
//        {
//            NSLog(@"- too small to fit in %d", MXKROOM_INPUT_TOOLBAR_VIEW_MEDIUM_IMAGE_SIZE);
//        }
//        
//        if (maxSize >= MXKROOM_INPUT_TOOLBAR_VIEW_LARGE_IMAGE_SIZE)
//        {
//            CGFloat factor = MXKROOM_INPUT_TOOLBAR_VIEW_LARGE_IMAGE_SIZE / maxSize;
//            largeFilesize = factor * factor * originalFileSize;
//        }
//        else
//        {
//            NSLog(@"- too small to fit in %d", MXKROOM_INPUT_TOOLBAR_VIEW_LARGE_IMAGE_SIZE);
//        }
//        
//        if (smallFilesize || mediumFilesize || largeFilesize)
//        {
//            currentAlert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"attachment_size_prompt"] message:nil style:MXKAlertStyleActionSheet];
//            __weak typeof(self) weakSelf = self;
//            
//            if (smallFilesize)
//            {
//                NSString *title = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"attachment_small"], [MXKTools fileSizeToString: (int)smallFilesize]];
//                [currentAlert addActionWithTitle:title style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
//                    __strong __typeof(weakSelf)strongSelf = weakSelf;
//                    strongSelf->currentAlert = nil;
//                    
//                    // Send the small image
//                    UIImage *smallImage = [MXKTools resize:selectedImage toFitInSize:CGSizeMake(MXKROOM_INPUT_TOOLBAR_VIEW_SMALL_IMAGE_SIZE, MXKROOM_INPUT_TOOLBAR_VIEW_SMALL_IMAGE_SIZE)];
//                    [strongSelf.delegate roomInputToolbarView:weakSelf sendImage:smallImage];
//                }];
//            }
//            
//            if (mediumFilesize)
//            {
//                NSString *title = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"attachment_medium"], [MXKTools fileSizeToString: (int)mediumFilesize]];
//                [currentAlert addActionWithTitle:title style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
//                    __strong __typeof(weakSelf)strongSelf = weakSelf;
//                    strongSelf->currentAlert = nil;
//                    
//                    // Send the medium image
//                    UIImage *mediumImage = [MXKTools resize:selectedImage toFitInSize:CGSizeMake(MXKROOM_INPUT_TOOLBAR_VIEW_MEDIUM_IMAGE_SIZE, MXKROOM_INPUT_TOOLBAR_VIEW_MEDIUM_IMAGE_SIZE)];
//                    [strongSelf.delegate roomInputToolbarView:weakSelf sendImage:mediumImage];
//                }];
//            }
//            
//            if (largeFilesize)
//            {
//                NSString *title = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"attachment_large"], [MXKTools fileSizeToString: (int)largeFilesize]];
//                [currentAlert addActionWithTitle:title style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
//                    __strong __typeof(weakSelf)strongSelf = weakSelf;
//                    strongSelf->currentAlert = nil;
//                    
//                    // Send the large image
//                    UIImage *largeImage = [MXKTools resize:selectedImage toFitInSize:CGSizeMake(MXKROOM_INPUT_TOOLBAR_VIEW_LARGE_IMAGE_SIZE, MXKROOM_INPUT_TOOLBAR_VIEW_LARGE_IMAGE_SIZE)];
//                    [strongSelf.delegate roomInputToolbarView:weakSelf sendImage:largeImage];
//                }];
//            }
//            
//            NSString *title = [NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"attachment_original"], [MXKTools fileSizeToString: (int)originalFileSize]];
//            [currentAlert addActionWithTitle:title style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
//                __strong __typeof(weakSelf)strongSelf = weakSelf;
//                strongSelf->currentAlert = nil;
//                
//                // Send the original image
//                [strongSelf.delegate roomInputToolbarView:weakSelf sendImage:selectedImage];
//            }];
//            
//            currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
//                __strong __typeof(weakSelf)strongSelf = weakSelf;
//                strongSelf->currentAlert = nil;
//            }];
//            
//            currentAlert.sourceView = self;
//            
//            [self.delegate roomInputToolbarView:self presentMXKAlert:currentAlert];
//        }
//        else
//        {
//            // Send the original image
//            [self.delegate roomInputToolbarView:self sendImage:selectedImage];
//        }
//    } failure:^(NSError *error) {
//        
//        // Send the original image
//        [self.delegate roomInputToolbarView:self sendImage:selectedImage];
//    }];
//}

//- (void)getSelectedImageFileData:(NSDictionary*)selectedImageInfo success:(void (^)(NSData *selectedImageFileData))success failure:(void (^)(NSError *error))failure
//{
//    ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
//    [assetLibrary assetForURL:[selectedImageInfo valueForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
//        
//        NSData *selectedImageFileData;
//        
//        // asset may be nil if the image is not saved in photos library
//        if (asset)
//        {
//            ALAssetRepresentation* assetRepresentation = [asset defaultRepresentation];
//            
//            // Check whether the user select an image with a cropping
//            if ([[assetRepresentation metadata] objectForKey:@"AdjustmentXMP"])
//            {
//                // In case of crop we have to consider the original image
//                selectedImageFileData = UIImageJPEGRepresentation([selectedImageInfo objectForKey:UIImagePickerControllerOriginalImage], 0.9);
//            }
//            else
//            {
//                // cannot use assetRepresentation size to get the image size
//                // it gives wrong result with panorama picture
//                unsigned long imageDataSize = (unsigned long)[assetRepresentation size];
//                uint8_t* imageDataBytes = malloc(imageDataSize);
//                [assetRepresentation getBytes:imageDataBytes fromOffset:0 length:imageDataSize error:nil];
//                
//                selectedImageFileData = [NSData dataWithBytesNoCopy:imageDataBytes length:imageDataSize freeWhenDone:YES];
//            }
//        }
//        else
//        {
//            selectedImageFileData = UIImageJPEGRepresentation([selectedImageInfo objectForKey:UIImagePickerControllerOriginalImage], 0.9);
//        }
//        
//        if (success)
//        {
//            success (selectedImageFileData);
//        }
//    } failureBlock:^(NSError *err) {
//        
//        if (failure)
//        {
//            failure (err);
//        }
//    }];
//}

#pragma mark - Media Picker handling

//- (void)dismissMediaPicker
//{
//    mediaPicker.delegate = nil;
//    
//    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:dismissMediaPicker:)])
//    {
//        [self.delegate roomInputToolbarView:self dismissMediaPicker:mediaPicker];
//    }
//}
//
//- (void)moviePlayerThumbnailImageRequestDidFinishNotification:(NSNotification *)notification
//{
//    // Finalize video attachment
//    UIImage* videoThumbnail = [[notification userInfo] objectForKey:MPMoviePlayerThumbnailImageKey];
//    NSURL* selectedVideo = [tmpVideoPlayer contentURL];
//    [tmpVideoPlayer stop];
//    tmpVideoPlayer = nil;
//    
//    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:sendVideo:withThumbnail:)])
//    {
//        [self.delegate roomInputToolbarView:self sendVideo:selectedVideo withThumbnail:videoThumbnail];
//    }
//    else
//    {
//        NSLog(@"[RoomInputToolbarView] Attach video is not supported");
//    }
//    
//    [self dismissMediaPicker];
//}

@end
