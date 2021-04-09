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

const double kContextBarHeight = 24;
const NSTimeInterval kSendModeAnimationDuration = .15;
const NSTimeInterval kActionMenuAttachButtonAnimationDuration = .4;
const CGFloat kActionMenuAttachButtonSpringVelocity = 7;
const CGFloat kActionMenuAttachButtonSpringDamping = .45;
const NSTimeInterval kActionMenuContentAlphaAnimationDuration = .2;
const NSTimeInterval kActionMenuComposerHeightAnimationDuration = .3;

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
    self.inputContextViewHeightConstraint.constant = 0;

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
    growingTextView.placeholderColor = ThemeService.shared.theme.textTertiaryColor;
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
    self.inputTextBackgroundView.tintColor = ThemeService.shared.theme.roomInputTextBorder;
    
    if ([ThemeService.shared.themeId isEqualToString:@"light"])
    {
        [self.attachMediaButton setImage:[UIImage imageNamed:@"upload_icon"] forState:UIControlStateNormal];
    }
    else if ([ThemeService.shared.themeId isEqualToString:@"dark"] || [ThemeService.shared.themeId isEqualToString:@"black"])
    {
        [self.attachMediaButton setImage:[UIImage imageNamed:@"upload_icon_dark"] forState:UIControlStateNormal];
    }
    else if (@available(iOS 12.0, *) && ThemeService.shared.theme.userInterfaceStyle == UIUserInterfaceStyleDark) {
        [self.attachMediaButton setImage:[UIImage imageNamed:@"upload_icon_dark"] forState:UIControlStateNormal];
    }
    
    self.inputContextImageView.tintColor = ThemeService.shared.theme.textSecondaryColor;
    self.inputContextLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    self.inputContextButton.tintColor = ThemeService.shared.theme.textSecondaryColor;
    [self.actionsBar updateWithTheme:ThemeService.shared.theme];
}

#pragma mark -

- (void)setTextMessage:(NSString *)textMessage
{
    [self updateSendButtonWithMessage:textMessage];
    [super setTextMessage:textMessage];
}

- (void)setIsEncryptionEnabled:(BOOL)isEncryptionEnabled
{
    _isEncryptionEnabled = isEncryptionEnabled;
    
    [self updatePlaceholder];
}

- (void)setSendMode:(RoomInputToolbarViewSendMode)sendMode
{
    RoomInputToolbarViewSendMode previousMode = _sendMode;
    _sendMode = sendMode;

    self.actionMenuOpened = NO;
    [self updatePlaceholder];
    [self updateToolbarButtonLabelWithPreviousMode: previousMode];
}

- (void)updateToolbarButtonLabelWithPreviousMode:(RoomInputToolbarViewSendMode)previousMode
{
    UIImage *buttonImage;

    double updatedHeight = self.mainToolbarHeightConstraint.constant;
    
    switch (_sendMode)
    {
        case RoomInputToolbarViewSendModeReply:
            buttonImage = [UIImage imageNamed:@"send_icon"];
            self.inputContextImageView.image = [UIImage imageNamed:@"input_reply_icon"];
            self.inputContextLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_message_replying_to", @"Vector", nil), self.eventSenderDisplayName];

            self.inputContextViewHeightConstraint.constant = kContextBarHeight;
            updatedHeight += kContextBarHeight;
            self->growingTextView.maxHeight -= kContextBarHeight;
            break;
        case RoomInputToolbarViewSendModeEdit:
            buttonImage = [UIImage imageNamed:@"save_icon"];
            self.inputContextImageView.image = [UIImage imageNamed:@"input_edit_icon"];
            self.inputContextLabel.text = NSLocalizedStringFromTable(@"room_message_editing", @"Vector", nil);

            self.inputContextViewHeightConstraint.constant = kContextBarHeight;
            updatedHeight += kContextBarHeight;
            self->growingTextView.maxHeight -= kContextBarHeight;
            break;
        default:
            buttonImage = [UIImage imageNamed:@"send_icon"];

            if (previousMode != _sendMode)
            {
                updatedHeight -= kContextBarHeight;
                self->growingTextView.maxHeight += kContextBarHeight;
            }
            self.inputContextViewHeightConstraint.constant = 0;
            break;
    }
    
    [self.rightInputToolbarButton setImage:buttonImage forState:UIControlStateNormal];
    
    if (self.maxHeight && updatedHeight > self.maxHeight)
    {
        growingTextView.maxHeight -= updatedHeight - self.maxHeight;
        updatedHeight = self.maxHeight;
    }

    if (updatedHeight < self.mainToolbarMinHeightConstraint.constant)
    {
        updatedHeight = self.mainToolbarMinHeightConstraint.constant;
    }

    if (self.mainToolbarHeightConstraint.constant != updatedHeight)
    {
        [UIView animateWithDuration:kSendModeAnimationDuration animations:^{
            self.mainToolbarHeightConstraint.constant = updatedHeight;
            [self layoutIfNeeded];
            
            // Update toolbar superview
            if ([self.delegate respondsToSelector:@selector(roomInputToolbarView:heightDidChanged:completion:)])
            {
                [self.delegate roomInputToolbarView:self heightDidChanged:updatedHeight completion:nil];
            }
        }];
    }
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

#pragma mark - Actions

- (IBAction)cancelAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(roomInputToolbarViewDidTapCancel:)])
    {
        [self.delegate roomInputToolbarViewDidTapCancel:self];
    }
}

#pragma mark - HPGrowingTextView delegate

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *newText = [growingTextView.text stringByReplacingCharactersInRange:range withString:text];
    [self updateSendButtonWithMessage:newText];
    
    return YES;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)hpGrowingTextView
{
    // Clean the carriage return added on return press
    if ([self.textMessage isEqualToString:@"\n"])
    {
        self.textMessage = nil;
    }
    
    [super growingTextViewDidChange:hpGrowingTextView];
}

- (void)growingTextView:(HPGrowingTextView *)hpGrowingTextView willChangeHeight:(float)height
{
    // Update height of the main toolbar (message composer)
    CGFloat updatedHeight = height + (self.messageComposerContainerTopConstraint.constant + self.messageComposerContainerBottomConstraint.constant) + self.inputContextViewHeightConstraint.constant;
    
    if (self.maxHeight && updatedHeight > self.maxHeight)
    {
        hpGrowingTextView.maxHeight -= updatedHeight - self.maxHeight;
        updatedHeight = self.maxHeight;
    }

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
        self.actionMenuOpened = !self.isActionMenuOpened;
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

- (void)updateSendButtonWithMessage:(NSString *)textMessage
{
    self.actionMenuOpened = NO;
    
    if (textMessage.length)
    {
        self.rightInputToolbarButton.alpha = 1;
        self.messageComposerContainerTrailingConstraint.constant = self.frame.size.width - self.rightInputToolbarButton.frame.origin.x + 12;
    }
    else
    {
        self.rightInputToolbarButton.alpha = 0;
        self.messageComposerContainerTrailingConstraint.constant = 12;
    }
    
    [self layoutIfNeeded];
}

#pragma mark - properties

- (void)setActionMenuOpened:(BOOL)actionMenuOpened
{
    if (_actionMenuOpened != actionMenuOpened)
    {
        _actionMenuOpened = actionMenuOpened;
        
        if (self->growingTextView.internalTextView.selectedRange.length > 0)
        {
            NSRange range = self->growingTextView.internalTextView.selectedRange;
            range.location = range.location + range.length;
            range.length = 0;
            self->growingTextView.internalTextView.selectedRange = range;
        }

        if (_actionMenuOpened) {
            self.actionsBar.hidden = NO;
            [self.actionsBar animateWithShowIn:_actionMenuOpened completion:nil];
        }
        else
        {
            [self.actionsBar animateWithShowIn:_actionMenuOpened completion:^(BOOL finished) {
                self.actionsBar.hidden = YES;
            }];
        }
        
        [UIView animateWithDuration:kActionMenuAttachButtonAnimationDuration delay:0 usingSpringWithDamping:kActionMenuAttachButtonSpringDamping initialSpringVelocity:kActionMenuAttachButtonSpringVelocity options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.attachMediaButton.transform = actionMenuOpened ? CGAffineTransformMakeRotation(M_PI * 3 / 4) : CGAffineTransformIdentity;
        } completion:nil];
        
        [UIView animateWithDuration:kActionMenuContentAlphaAnimationDuration delay:_actionMenuOpened ? 0 : .1 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self->messageComposerContainer.alpha = actionMenuOpened ? 0 : 1;
            self.rightInputToolbarButton.alpha = self->growingTextView.text.length == 0 || actionMenuOpened ? 0 : 1;
        } completion:nil];
        
        [UIView animateWithDuration:kActionMenuComposerHeightAnimationDuration animations:^{
            if (actionMenuOpened)
            {
                self.mainToolbarHeightConstraint.constant = self.mainToolbarMinHeightConstraint.constant;
            }
            else
            {
                [self->growingTextView refreshHeight];
            }
            [self layoutIfNeeded];
            [self.delegate roomInputToolbarView:self heightDidChanged:self.mainToolbarHeightConstraint.constant completion:nil];
        }];
    }
}

#pragma mark - Clipboard - Handle image/data paste from general pasteboard

- (void)paste:(id)sender
{
    // TODO Custom here the validation screen for each available item
    
    [super paste:sender];
}

@end
