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

#import <MediaPlayer/MediaPlayer.h>

#import <Photos/Photos.h>

@interface RoomInputToolbarView()
{
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
    
    self.rightInputToolbarButton.hidden = YES;
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
    
    if (self.rightInputToolbarButton.isEnabled && self.rightInputToolbarButton.isHidden)
    {
        self.rightInputToolbarButton.hidden = NO;
        self.attachMediaButton.hidden = YES;
        self.voiceCallButton.hidden = YES;
        
        self.messageComposerContainerTrailingConstraint.constant = self.frame.size.width - self.rightInputToolbarButton.frame.origin.x + 4;
    }
    else if (!self.rightInputToolbarButton.isEnabled && !self.rightInputToolbarButton.isHidden)
    {
        self.rightInputToolbarButton.hidden = YES;
        self.attachMediaButton.hidden = NO;
        self.voiceCallButton.hidden = NO;
        
        self.messageComposerContainerTrailingConstraint.constant = self.frame.size.width - self.attachMediaButton.frame.origin.x + 4;
    }
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    // FIXME GFO: Check whether mainToolbarHeightConstraint can be removed. If yes, remove it and remove
    // this overidden method, the original one should be fine.
    
    // Update height of the main toolbar (message composer)
    self.mainToolbarHeightConstraint.constant = height + (self.messageComposerContainerTopConstraint.constant + self.messageComposerContainerBottomConstraint.constant);
    
    // Update toolbar superview
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:heightDidChanged:completion:)])
    {
        [self.delegate roomInputToolbarView:self heightDidChanged:self.mainToolbarHeightConstraint.constant completion:nil];
    }
}

#pragma mark - Override MXKRoomInputToolbarView

- (IBAction)onTouchUpInside:(UIButton*)button
{
    if (button == self.attachMediaButton)
    {
        // Check whether media attachment is supported
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:presentViewController:)])
        {
            // MediaPickerViewController is based on the Photos framework. So it is available only for iOS 8 and later.
            Class PHAsset_class = NSClassFromString(@"PHAsset");
            if (PHAsset_class)
            {
                mediaPicker = [MediaPickerViewController mediaPickerViewController];
                mediaPicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
                mediaPicker.multipleSelections = YES;
                mediaPicker.selectionButtonCustomLabel = NSLocalizedStringFromTable(@"media_picker_attach", @"Vector", nil);
                mediaPicker.delegate = self;
                UINavigationController *navigationController = [UINavigationController new];
                [navigationController pushViewController:mediaPicker animated:NO];
                
                [self.delegate roomInputToolbarView:self presentViewController:navigationController];
            }
            else
            {
                // We use UIImagePickerController by default for iOS < 8
                self.leftInputToolbarButton = self.attachMediaButton;
                [super onTouchUpInside:self.leftInputToolbarButton];
            }
        }
        else
        {
            NSLog(@"[RoomInputToolbarView] Attach media is not supported");
        }
    }
    else if (button == self.voiceCallButton)
    {
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:placeCallWithVideo:)])
        {
            [self.delegate roomInputToolbarView:self placeCallWithVideo:NO];
        }
    }
    
    [super onTouchUpInside:button];
}


- (void)destroy
{
    [self dismissMediaPicker];
    
    [super destroy];
}

#pragma mark - MediaPickerViewController Delegate

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectImage:(UIImage*)image withURL:(NSURL *)imageURL 
{
    [self dismissMediaPicker];
    
    [self sendSelectedImage:image withCompressionMode:MXKRoomInputToolbarCompressionModePrompt andLocalURL:imageURL];
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectVideo:(NSURL*)videoURL isCameraRecording:(BOOL)isCameraRecording
{
    [self dismissMediaPicker];
    
    [self sendSelectedVideo:videoURL isCameraRecording:isCameraRecording];
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectAssets:(NSArray *)assets
{
    [self dismissMediaPicker];
    
    // We don't prompt user about image compression if several items have been selected
    MXKRoomInputToolbarCompressionMode imageCompressionMode = (assets.count > 1) ? MXKRoomInputToolbarCompressionModeMedium : MXKRoomInputToolbarCompressionModePrompt;
    
    PHContentEditingInputRequestOptions *editOptions = [[PHContentEditingInputRequestOptions alloc] init];
    for (NSUInteger index = 0; index < assets.count; index++)
    {
        PHAsset *asset = assets[index];
        [asset requestContentEditingInputWithOptions:editOptions
                                   completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                                       
                                       if (contentEditingInput.mediaType == PHAssetMediaTypeImage)
                                       {
                                           // Here the fullSizeImageURL is related to a local file path
                                           NSData *data = [NSData dataWithContentsOfURL:contentEditingInput.fullSizeImageURL];
                                           UIImage *image = [UIImage imageWithData:data];
                                           
                                           [self sendSelectedImage:image withCompressionMode:imageCompressionMode andLocalURL:contentEditingInput.fullSizeImageURL];
                                       }
                                       else if (contentEditingInput.mediaType == PHAssetMediaTypeVideo)
                                       {
                                           if ([contentEditingInput.avAsset isKindOfClass:[AVURLAsset class]])
                                           {
                                               AVURLAsset *avURLAsset = (AVURLAsset*)contentEditingInput.avAsset;
                                               [self sendSelectedVideo:[avURLAsset URL] isCameraRecording:NO];
                                           }
                                           else
                                           {
                                               NSLog(@"[RoomInputToolbarView] Selected video asset is not initialized from an URL!");
                                           }
                                       }
                                   }];
    }
}

#pragma mark - Media picker handling

- (void)dismissMediaPicker
{
    if (mediaPicker)
    {
        [mediaPicker withdrawViewControllerAnimated:YES completion:nil];
        mediaPicker = nil;
    }
}

#pragma mark - Clipboard - Handle image/data paste from general pasteboard

- (void)paste:(id)sender
{
    // TODO Custom here the validation screen for each available item
    
    [super paste:sender];
}

@end
