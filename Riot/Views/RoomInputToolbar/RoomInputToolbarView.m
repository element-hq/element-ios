/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "RiotDesignValues.h"

#import "GBDeviceInfo_iOS.h"

#import "UINavigationController+Riot.h"

#import <Photos/Photos.h>

#import <MobileCoreServices/MobileCoreServices.h>

#import "CameraViewController.h"

@interface RoomInputToolbarView()
{
    CameraViewController *cameraController;

    // The call type selection (voice or video)
    UIAlertController *callActionSheet;
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
    
    _supportCallOption = YES;
    
    self.rightInputToolbarButton.hidden = YES;
    
    [self.rightInputToolbarButton setTitleColor:kRiotColorGreen forState:UIControlStateNormal];
    [self.rightInputToolbarButton setTitleColor:kRiotColorGreen forState:UIControlStateHighlighted];
    
    self.isEncryptionEnabled = _isEncryptionEnabled;
}

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    // Remove default toolbar background color
    self.backgroundColor = [UIColor clearColor];
    
    self.separatorView.backgroundColor = kRiotAuxiliaryColor;
    
    // Custom the growingTextView display
    growingTextView.layer.cornerRadius = 0;
    growingTextView.layer.borderWidth = 0;
    growingTextView.backgroundColor = [UIColor clearColor];
    
    growingTextView.font = [UIFont systemFontOfSize:15];
    growingTextView.textColor = kRiotPrimaryTextColor;
    growingTextView.tintColor = kRiotColorGreen;
    
    growingTextView.internalTextView.keyboardAppearance = kRiotKeyboard;
}

#pragma mark -

- (void)setSupportCallOption:(BOOL)supportCallOption
{
    if (_supportCallOption != supportCallOption)
    {
        _supportCallOption = supportCallOption;
        
        if (supportCallOption)
        {
            self.voiceCallButtonWidthConstraint.constant = 46;
        }
        else
        {
            self.voiceCallButtonWidthConstraint.constant = 0;
        }
        
        [self setNeedsUpdateConstraints];
    }
}

- (void)setIsEncryptionEnabled:(BOOL)isEncryptionEnabled
{
    _isEncryptionEnabled = isEncryptionEnabled;
    
    // Consider the default placeholder
    NSString *placeholder= NSLocalizedStringFromTable(@"room_message_short_placeholder", @"Vector", nil);
    
    if (_isEncryptionEnabled)
    {
        self.encryptedRoomIcon.image = [UIImage imageNamed:@"e2e_verified"];
        
        // Check the device screen size before using large placeholder
        if ([GBDeviceInfo deviceInfo].family == GBDeviceFamilyiPad || [GBDeviceInfo deviceInfo].displayInfo.display >= GBDeviceDisplay4p7Inch)
        {
            placeholder = NSLocalizedStringFromTable(@"encrypted_room_message_placeholder", @"Vector", nil);
        }
    }
    else
    {
        self.encryptedRoomIcon.image = [UIImage imageNamed:@"e2e_unencrypted"];
        
        // Check the device screen size before using large placeholder
        if ([GBDeviceInfo deviceInfo].family == GBDeviceFamilyiPad || [GBDeviceInfo deviceInfo].displayInfo.display >= GBDeviceDisplay4p7Inch)
        {
            placeholder = NSLocalizedStringFromTable(@"room_message_placeholder", @"Vector", nil);
        }
    }
    
    
    self.placeholder = placeholder;
}

- (void)setActiveCall:(BOOL)activeCall
{
    if (_activeCall != activeCall)
    {
        _activeCall = activeCall;

        self.voiceCallButton.hidden = (_activeCall || !self.rightInputToolbarButton.hidden);
        self.hangupCallButton.hidden = (!_activeCall || !self.rightInputToolbarButton.hidden);
    }
}

#pragma mark - HPGrowingTextView delegate

//- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)hpGrowingTextView
//{
//    // The return sends the message rather than giving a carriage return.
//    [self onTouchUpInside:self.rightInputToolbarButton];
//    
//    return NO;
//}

- (void)growingTextViewDidChange:(HPGrowingTextView *)hpGrowingTextView
{
    // Clean the carriage return added on return press
    if ([self.textMessage isEqualToString:@"\n"])
    {
        self.textMessage = nil;
    }
    
    [super growingTextViewDidChange:hpGrowingTextView];
    
    if (self.rightInputToolbarButton.isEnabled && self.rightInputToolbarButton.isHidden)
    {
        self.rightInputToolbarButton.hidden = NO;
        self.attachMediaButton.hidden = YES;
        self.voiceCallButton.hidden = YES;
        self.hangupCallButton.hidden = YES;
        
        self.messageComposerContainerTrailingConstraint.constant = self.frame.size.width - self.rightInputToolbarButton.frame.origin.x + 4;
    }
    else if (!self.rightInputToolbarButton.isEnabled && !self.rightInputToolbarButton.isHidden)
    {
        self.rightInputToolbarButton.hidden = YES;
        self.attachMediaButton.hidden = NO;
        self.voiceCallButton.hidden = _activeCall;
        self.hangupCallButton.hidden = !_activeCall;
        
        self.messageComposerContainerTrailingConstraint.constant = self.frame.size.width - self.attachMediaButton.frame.origin.x + 4;
    }
}

- (void)growingTextView:(HPGrowingTextView *)hpGrowingTextView willChangeHeight:(float)height
{
    // Update height of the main toolbar (message composer)
    CGFloat updatedHeight = height + (self.messageComposerContainerTopConstraint.constant + self.messageComposerContainerBottomConstraint.constant);
    
    if (updatedHeight < self.mainToolbarMinHeightConstraint.constant)
    {
        updatedHeight = self.mainToolbarMinHeightConstraint.constant;
    }
    
    self.mainToolbarHeightConstraint.constant = updatedHeight;
    
    // Update toolbar superview
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:heightDidChanged:completion:)])
    {
        [self.delegate roomInputToolbarView:self heightDidChanged:updatedHeight completion:nil];
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
                cameraController = [CameraViewController cameraViewController];
                cameraController.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
                cameraController.delegate = self;
                UINavigationController *navigationController = [UINavigationController new];
                [navigationController pushViewController:cameraController animated:NO];
                
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
            // Ask the user the kind of the call: voice or video?
            callActionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

            __weak typeof(self) weakSelf = self;
            [callActionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"voice", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->callActionSheet = nil;
                                                                   
                                                                   [self.delegate roomInputToolbarView:self placeCallWithVideo:NO];
                                                               }
                                                               
                                                           }]];
            
            [callActionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"video", @"Vector", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  
                                                                  if (weakSelf)
                                                                  {
                                                                      typeof(self) self = weakSelf;
                                                                      self->callActionSheet = nil;
                                                                      
                                                                      [self.delegate roomInputToolbarView:self placeCallWithVideo:YES];
                                                                  }
                                                                  
                                                              }]];
            
            [callActionSheet addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  
                                                                  if (weakSelf)
                                                                  {
                                                                      typeof(self) self = weakSelf;
                                                                      self->callActionSheet = nil;
                                                                  }
                                                                  
                                                              }]];
            
            [callActionSheet popoverPresentationController].sourceView = self.voiceCallButton;
            [callActionSheet popoverPresentationController].sourceRect = self.voiceCallButton.bounds;
            [self.window.rootViewController presentViewController:callActionSheet animated:YES completion:nil];
        }
    }
    else if (button == self.hangupCallButton)
    {
        if ([self.delegate respondsToSelector:@selector(roomInputToolbarViewHangupCall:)])
        {
            [self.delegate roomInputToolbarViewHangupCall:self];
        }
    }

    [super onTouchUpInside:button];
}


- (void)destroy
{
    [self dismissCameraController];

    if (callActionSheet)
    {
        [callActionSheet dismissViewControllerAnimated:NO completion:nil];
        callActionSheet = nil;
    }
    
    [super destroy];
}

#pragma mark - CameraViewController Delegate

- (void)cameraViewController:(CameraViewController *)cameraViewController didSelectImage:(NSData*)imageData withMimeType:(NSString *)mimetype isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset
{
    [self dismissCameraController];
    
    [self sendSelectedImage:imageData withMimeType:mimetype andCompressionMode:MXKRoomInputToolbarCompressionModePrompt isPhotoLibraryAsset:isPhotoLibraryAsset];
}

- (void)cameraViewController:(CameraViewController *)cameraViewController didSelectVideo:(NSURL*)videoURL isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset
{
    [self dismissCameraController];

    [self sendSelectedVideo:videoURL isPhotoLibraryAsset:isPhotoLibraryAsset];
}

#pragma mark - camera controller handling

- (void)dismissCameraController
{
    if (cameraController)
    {
        [cameraController.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        [cameraController destroy];
        cameraController = nil;

    }
}

#pragma mark - Clipboard - Handle image/data paste from general pasteboard

- (void)paste:(id)sender
{
    // TODO Custom here the validation screen for each available item
    
    [super paste:sender];
}

@end
