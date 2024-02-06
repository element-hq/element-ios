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

#import "RoomTitleView.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation RoomTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomTitleView class])
                          bundle:[NSBundle bundleForClass:[RoomTitleView class]]];
}

- (void)dealloc
{
    _roomPreviewData = nil;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.badgeImageView.image = nil;
    
    if (_titleMask)
    {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
        [tap setNumberOfTouchesRequired:1];
        [tap setNumberOfTapsRequired:1];
        [tap setDelegate:self];
        [self.titleMask addGestureRecognizer:tap];
        self.titleMask.userInteractionEnabled = YES;
        self.dotView.layer.masksToBounds = YES;
        self.dotView.layer.cornerRadius = CGRectGetMidX(self.dotView.bounds);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.pictureView.layer.cornerRadius = self.pictureView.bounds.size.width / 2.;

    if (self.superview)
    {
        // Force the title view layout by adding 2 new constraints on the UINavigationBarContentView instance.
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.superview
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0f
                                                                          constant:0.0f];
        NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                             attribute:NSLayoutAttributeCenterX
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.superview
                                                                             attribute:NSLayoutAttributeCenterX
                                                                            multiplier:1.0f
                                                                              constant:0.0f];
        
        [NSLayoutConstraint activateConstraints:@[topConstraint, centerXConstraint]];
    }
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];

    self.backgroundColor = UIColor.clearColor;
    self.displayNameTextField.textColor = (self.mxRoom.summary.displayName.length ? ThemeService.shared.theme.textPrimaryColor : ThemeService.shared.theme.textSecondaryColor);
    self.typingLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    self.dotView.backgroundColor = ThemeService.shared.theme.warningColor;
    self.missedDiscussionsBadgeLabel.textColor = ThemeService.shared.theme.tintColor;
}

- (void)setRoomPreviewData:(RoomPreviewData *)roomPreviewData
{
    _roomPreviewData = roomPreviewData;
    
    [self refreshDisplay];
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    // Consider in priority the preview data (if any)
    if (self.roomPreviewData)
    {
        
//        self.displayNameTextField.text = self.roomPreviewData.roomName;
        // Assuming displayNameTextField is a UITextField
        NSString *roomName = self.roomPreviewData.roomName;

        // Replace [TG] with an image
        NSString *replacementText = @"[TG] ";
        UIImage *image = [UIImage imageNamed:@"chatimg"];
        NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
        textAttachment.image = image;
        NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:textAttachment];

        // Replace $ with an image
        NSString *dollarReplacementText = @"$";
        UIImage *dollarImage = [UIImage imageNamed:@"dollar"];
        NSTextAttachment *dollarTextAttachment = [[NSTextAttachment alloc] init];
        dollarTextAttachment.image = dollarImage;
        NSAttributedString *dollarImageString = [NSAttributedString attributedStringWithAttachment:dollarTextAttachment];

        NSString *modifiedRoomName = roomName;

        // Check if the string starts with [TG] and replace with the first image
        if ([roomName hasPrefix:replacementText]) {
            modifiedRoomName = [modifiedRoomName substringFromIndex:replacementText.length];
            // Append the first image to the modifiedRoomName
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:modifiedRoomName];
            [attributedString insertAttributedString:imageString atIndex:0];
            self.displayNameTextField.text = modifiedRoomName;
            [self.displayNameTextField setAttributedText:attributedString];
        } else if ([roomName containsString:replacementText]) {
            // If [TG] is not at the beginning, just remove it
            modifiedRoomName = [modifiedRoomName stringByReplacingOccurrencesOfString:replacementText withString:@""];
        }

        // Check if the string starts with $ and replace with the second image
        if ([roomName hasPrefix:dollarReplacementText]) {
            modifiedRoomName = [modifiedRoomName substringFromIndex:dollarReplacementText.length];
            // Append the second image to the modifiedRoomName
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:modifiedRoomName];
            [attributedString insertAttributedString:dollarImageString atIndex:0];
            self.displayNameTextField.text = modifiedRoomName;
            [self.displayNameTextField setAttributedText:attributedString];
        } else if ([roomName containsString:dollarReplacementText]) {
            // If $ is not at the beginning, just remove it
            modifiedRoomName = [modifiedRoomName stringByReplacingOccurrencesOfString:dollarReplacementText withString:@""];
        }

        // If neither [TG] nor $ is found, display the original string
        if (![roomName hasPrefix:replacementText] && ![roomName hasPrefix:dollarReplacementText]) {
            self.displayNameTextField.text = roomName;
        }

    }
    else if (self.mxRoom)
    {
        if (self.mxRoom.directUserId)
        {
            MXUser *contact = [self.mxRoom.mxSession userWithUserId:self.mxRoom.directUserId];
            self.presenceIndicatorView.borderColor = ThemeService.shared.theme.headerBackgroundColor;
            self.presenceIndicatorView.delegate = self;
            [self.presenceIndicatorView configureWithUserId:self.mxRoom.directUserId presence:contact.presence];
        }
        else
        {
            [self.presenceIndicatorView stopListeningPresenceUpdates];
        }
        
        NSString *roomName = self.mxRoom.summary.displayName;

        // Replace [TG] with an image
        NSString *replacementText = @"[TG] ";
        UIImage *image = [UIImage imageNamed:@"chatimg"];
        NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
        textAttachment.image = image;
        NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:textAttachment];

        // Replace $ with an image
        NSString *dollarReplacementText = @"$";
        UIImage *dollarImage = [UIImage imageNamed:@"dollar"];
        NSTextAttachment *dollarTextAttachment = [[NSTextAttachment alloc] init];
        dollarTextAttachment.image = dollarImage;
        NSAttributedString *dollarImageString = [NSAttributedString attributedStringWithAttachment:dollarTextAttachment];

        NSString *modifiedRoomName = roomName;

        // Check if the string starts with [TG] and replace with the first image
        if ([roomName hasPrefix:replacementText]) {
            modifiedRoomName = [modifiedRoomName substringFromIndex:replacementText.length];
            // Append the first image to the modifiedRoomName
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:modifiedRoomName];
            [attributedString insertAttributedString:imageString atIndex:0];
            self.displayNameTextField.text = modifiedRoomName;
            [self.displayNameTextField setAttributedText:attributedString];
        } else if ([roomName containsString:replacementText]) {
            // If [TG] is not at the beginning, just remove it
            modifiedRoomName = [modifiedRoomName stringByReplacingOccurrencesOfString:replacementText withString:@""];
        }

        // Check if the string starts with $ and replace with the second image
        if ([roomName hasPrefix:dollarReplacementText]) {
            modifiedRoomName = [modifiedRoomName substringFromIndex:dollarReplacementText.length];
            // Append the second image to the modifiedRoomName
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:modifiedRoomName];
            [attributedString insertAttributedString:dollarImageString atIndex:0];
            self.displayNameTextField.text = modifiedRoomName;
            [self.displayNameTextField setAttributedText:attributedString];
        } else if ([roomName containsString:dollarReplacementText]) {
            // If $ is not at the beginning, just remove it
            modifiedRoomName = [modifiedRoomName stringByReplacingOccurrencesOfString:dollarReplacementText withString:@""];
        }

        // If neither [TG] nor $ is found, display the original string
        if (![roomName hasPrefix:replacementText] && ![roomName hasPrefix:dollarReplacementText]) {
            self.displayNameTextField.text = roomName;
        }
        if (!self.displayNameTextField.text.length)
        {
            self.displayNameTextField.text = [VectorL10n roomDisplaynameEmptyRoom];
            self.displayNameTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
        }
        else
        {
            self.displayNameTextField.textColor = ThemeService.shared.theme.textPrimaryColor;
        }
    }
}

- (void)destroy
{
    self.tapGestureDelegate = nil;
    
    [super destroy];
}

- (void)reportTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    if (self.tapGestureDelegate)
    {
        [self.tapGestureDelegate roomTitleView:self recognizeTapGesture:tapGestureRecognizer];
    }
}

- (void)updateLayoutForOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        self.missedDiscussionsBadgeLabel.font = [UIFont systemFontOfSize:10];
        self.missedDiscussionsBadgeLabelLeadingConstraint.constant = -24;
        self.pictureViewWidthConstraint.constant = 28;
        self.pictureViewHeightConstraint.constant = 28;
        self.displayNameTextField.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        self.typingLabel.font = [UIFont systemFontOfSize:10];
        self.dotViewCenterYConstraint.constant = -2;
    }
    else
    {
        self.missedDiscussionsBadgeLabel.font = [UIFont systemFontOfSize:15];
        self.missedDiscussionsBadgeLabelLeadingConstraint.constant = -32;
        self.pictureViewWidthConstraint.constant = 32;
        self.pictureViewHeightConstraint.constant = 32;
        self.displayNameTextField.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        self.typingLabel.font = [UIFont systemFontOfSize:12];
        self.dotViewCenterYConstraint.constant = -1;
   }
}

- (void)setTypingNotificationString:(NSString *)typingNotificationString
{
    if (typingNotificationString.length > 0)
    {
        self.typingLabel.text = typingNotificationString;
        [self layoutIfNeeded];

        [UIView animateWithDuration:.1 animations:^{
            self.typingLabel.alpha = 1;
            self.displayNameCenterYConstraint.constant = -8;
            [self layoutIfNeeded];
        }];
    }
    else
    {
        [UIView animateWithDuration:.1 animations:^{
            self.typingLabel.alpha = 0;
            self.displayNameCenterYConstraint.constant = 0;
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.typingLabel.text = nil;
        }];
    }
}

- (NSString *)typingNotificationString
{
    return self.typingLabel.text;
}

#pragma mark - PresenceIndicatorViewDelegate

- (void)presenceIndicatorViewDidUpdateVisibility:(PresenceIndicatorView *)presenceIndicatorView isHidden:(BOOL)isHidden
{
    if (isHidden)
    {
        [self.badgeImageViewLeadingToPictureViewConstraint setPriority:UILayoutPriorityDefaultLow];
        [self.badgeImageViewCenterYToDisplayNameConstraint setPriority:UILayoutPriorityDefaultLow];
        [self.badgeImageViewToPictureViewBottomConstraint setPriority:UILayoutPriorityRequired];
        [self.badgeImageViewToPictureViewTrailingConstraint setPriority:UILayoutPriorityRequired];
    }
    else
    {
        [self.badgeImageViewToPictureViewBottomConstraint setPriority:UILayoutPriorityDefaultLow];
        [self.badgeImageViewToPictureViewTrailingConstraint setPriority:UILayoutPriorityDefaultLow];
        [self.badgeImageViewLeadingToPictureViewConstraint setPriority:UILayoutPriorityRequired];
        [self.badgeImageViewCenterYToDisplayNameConstraint setPriority:UILayoutPriorityRequired];
    }
}

@end
