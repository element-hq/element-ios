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

#import "ThemeService.h"
#import "Riot-Swift.h"

#import "GBDeviceInfo_iOS.h"

#import "UINavigationController+Riot.h"

#import "WidgetManager.h"
#import "IntegrationManagerViewController.h"

@interface RoomInputToolbarView()
{
    // The intermediate action sheet
    UIAlertController *actionSheet;
}

@end

@implementation RoomInputToolbarView
@dynamic delegate;

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
    
    _sendMode = RoomInputToolbarViewSendModeSend;
    
    [self.rightInputToolbarButton setTitle:nil forState:UIControlStateNormal];
    [self.rightInputToolbarButton setTitle:nil forState:UIControlStateHighlighted];

    self.isEncryptionEnabled = _isEncryptionEnabled;
}

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    // Remove default toolbar background color
    self.backgroundColor = [UIColor clearColor];
    
    // Custom the growingTextView display
    growingTextView.layer.cornerRadius = 0;
    growingTextView.layer.borderWidth = 0;
    growingTextView.backgroundColor = [UIColor clearColor];
    
    growingTextView.font = [UIFont systemFontOfSize:15];
    growingTextView.textColor = ThemeService.shared.theme.textPrimaryColor;
    growingTextView.tintColor = ThemeService.shared.theme.tintColor;
    
    growingTextView.internalTextView.showsVerticalScrollIndicator = NO;
    
    growingTextView.internalTextView.keyboardAppearance = ThemeService.shared.theme.keyboardAppearance;
    if (growingTextView.isFirstResponder)
    {
        [growingTextView resignFirstResponder];
        [growingTextView becomeFirstResponder];
    }

    self.attachMediaButton.accessibilityLabel = NSLocalizedStringFromTable(@"room_accessibility_upload", @"Vector", nil);
    
    UIImage *image = [UIImage imageNamed:@"input_text_background"];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(9, 15, 10, 16)];
    self.inputTextBackgroundView.image = image;
}

#pragma mark -

- (void)setIsEncryptionEnabled:(BOOL)isEncryptionEnabled
{
    _isEncryptionEnabled = isEncryptionEnabled;
    
    [self updatePlaceholder];
}

- (void)setSendMode:(RoomInputToolbarViewSendMode)sendMode
{
    _sendMode = sendMode;

    [self updatePlaceholder];
}

- (void)updatePlaceholder
{
    // Consider the default placeholder
    
    NSString *placeholder;
    
    // Check the device screen size before using large placeholder
    BOOL shouldDisplayLargePlaceholder = [GBDeviceInfo deviceInfo].family == GBDeviceFamilyiPad || [GBDeviceInfo deviceInfo].displayInfo.display >= GBDeviceDisplay5p8Inch;
    
    if (!shouldDisplayLargePlaceholder)
    {
        switch (_sendMode)
        {
            case RoomInputToolbarViewSendModeReply:
                placeholder = NSLocalizedStringFromTable(@"room_message_reply_to_short_placeholder", @"Vector", nil);
                break;

            default:
                placeholder = NSLocalizedStringFromTable(@"room_message_short_placeholder", @"Vector", nil);
                break;
        }
    }
    else
    {
        if (_isEncryptionEnabled)
        {
            switch (_sendMode)
            {
                case RoomInputToolbarViewSendModeReply:
                    placeholder = NSLocalizedStringFromTable(@"encrypted_room_message_reply_to_placeholder", @"Vector", nil);
                    break;

                default:
                    placeholder = NSLocalizedStringFromTable(@"encrypted_room_message_placeholder", @"Vector", nil);
                    break;
            }
        }
        else
        {
            switch (_sendMode)
            {
                case RoomInputToolbarViewSendModeReply:
                    placeholder = NSLocalizedStringFromTable(@"room_message_reply_to_placeholder", @"Vector", nil);
                    break;

                default:
                    placeholder = NSLocalizedStringFromTable(@"room_message_placeholder", @"Vector", nil);
                    break;
            }
        }
    }
    
    self.placeholder = placeholder;
}

#pragma mark - HPGrowingTextView delegate

- (void)growingTextViewDidChange:(HPGrowingTextView *)hpGrowingTextView
{
    // Clean the carriage return added on return press
    if ([self.textMessage isEqualToString:@"\n"])
    {
        self.textMessage = nil;
    }
    
    [super growingTextViewDidChange:hpGrowingTextView];
    
    if (self.rightInputToolbarButton.isEnabled && !self.rightInputToolbarButton.alpha)
    {
        [UIView animateWithDuration:.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:8 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.rightInputToolbarButton.alpha = 1;
            self.messageComposerContainerTrailingConstraint.constant = self.frame.size.width - self.rightInputToolbarButton.frame.origin.x + 12;
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
    }
    else if (!self.rightInputToolbarButton.isEnabled && self.rightInputToolbarButton.alpha)
    {
        [UIView animateWithDuration:.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:8 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.rightInputToolbarButton.alpha = 0;
            self.messageComposerContainerTrailingConstraint.constant = 12;
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
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
            // Ask the user the kind of the call: voice or video?
            actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

            __weak typeof(self) weakSelf = self;
            
            [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_action_camera", @"Vector", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              if (weakSelf)
                                                              {
                                                                  typeof(self) self = weakSelf;
                                                                  self->actionSheet = nil;
                                                                  
                                                                  [self.delegate roomInputToolbarViewDidTapCamera:self];
                                                              }
                                                          }]];
            
            
            [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_action_send_photo_or_video", @"Vector", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {

                                                              if (weakSelf)
                                                              {
                                                                  typeof(self) self = weakSelf;
                                                                  self->actionSheet = nil;

                                                                  [self.delegate roomInputToolbarViewDidTapMediaLibrary:self];
                                                              }

                                                          }]];

            if (BuildSettings.allowSendingStickers)
            {
                [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_action_send_sticker", @"Vector", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        self->actionSheet = nil;
                        
                        [self.delegate roomInputToolbarViewPresentStickerPicker:self];
                    }
                    
                }]];
            }
            
            [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_action_send_file", @"Vector", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              if (weakSelf)
                                                              {
                                                                  typeof(self) self = weakSelf;
                                                                  self->actionSheet = nil;
                                                                  
                                                                  [self.delegate roomInputToolbarViewDidTapFileUpload:self];
                                                              }
                                                          }]];

            [actionSheet addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {

                                                              if (weakSelf)
                                                              {
                                                                  typeof(self) self = weakSelf;
                                                                  self->actionSheet = nil;
                                                              }

                                                          }]];

            [actionSheet popoverPresentationController].sourceView = self.attachMediaButton;
            [actionSheet popoverPresentationController].sourceRect = self.attachMediaButton.bounds;
            [self.window.rootViewController presentViewController:actionSheet animated:YES completion:nil];
        }
        else
        {
            NSLog(@"[RoomInputToolbarView] Attach media is not supported");
        }
    }

    [super onTouchUpInside:button];
}

- (void)destroy
{
    if (actionSheet)
    {
        [actionSheet dismissViewControllerAnimated:NO completion:nil];
        actionSheet = nil;
    }
    
    [super destroy];
}

#pragma mark - Clipboard - Handle image/data paste from general pasteboard

- (void)paste:(id)sender
{
    // TODO Custom here the validation screen for each available item
    
    [super paste:sender];
}

@end
