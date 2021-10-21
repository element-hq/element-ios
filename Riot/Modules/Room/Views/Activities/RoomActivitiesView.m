/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2019 New Vector Ltd

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

#import "RoomActivitiesView.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import <objc/runtime.h>

@interface RoomActivitiesView ()
{
    // The default height as defined in the xib
    CGFloat xibMainHeightConstraint;
}

@end

@implementation RoomActivitiesView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomActivitiesView class])
                          bundle:[NSBundle bundleForClass:[RoomActivitiesView class]]];
}

- (CGFloat)height
{
    [self checkHeight:NO];

    return self.mainHeightConstraint.constant;
}

- (void)setHeight:(CGFloat)height notify:(BOOL)notify
{
    if (self.mainHeightConstraint.constant != height)
    {
        CGFloat oldHeight = self.mainHeightConstraint.constant;
        self.mainHeightConstraint.constant = height;

        if (notify && self.delegate)
        {
            [self.delegate didChangeHeight:self oldHeight:oldHeight newHeight:self.mainHeightConstraint.constant];
        }
    }
}

- (void)checkHeight:(BOOL)notify
{
    if (!self.messageTextView.isHidden)
    {
        // Compute the required height to display the text in messageTextView
        CGFloat height = [self.messageTextView sizeThatFits:self.messageTextView.frame.size].height + 20; // 20 is the top and bottom margins in xib

        height = MAX(xibMainHeightConstraint, height);
        if (height != self.mainHeightConstraint.constant)
        {
            [self setHeight:height notify:notify];
        }
    }
    else if (!self.unsentMessagesContentView.isHidden)
    {
        CGSize fittingSize = CGSizeMake(self.bounds.size.width, UILayoutFittingCompressedSize.height);
        CGFloat height = [self.unsentMessagesContentView systemLayoutSizeFittingSize:fittingSize].height + 4;

        height = MAX(xibMainHeightConstraint, height);
        if (height != self.mainHeightConstraint.constant)
        {
            [self setHeight:height notify:notify];
        }
    }
    else
    {
        // In other use case, come back to the default xib value
        if (self.mainHeightConstraint.constant != xibMainHeightConstraint)
        {
            [self setHeight:xibMainHeightConstraint notify:notify];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // Check the required height in case on view update
    // We need to delay the check in case of screen rotation to get the right screen width
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkHeight:YES];
    });
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Adjust text view
    // Remove the container inset: this operation impacts only the vertical margin.
    // Reset textContainer.lineFragmentPadding to remove horizontal margin.
    self.messageTextView.textContainerInset = UIEdgeInsetsZero;
    self.messageTextView.textContainer.lineFragmentPadding = 0;

    xibMainHeightConstraint = self.mainHeightConstraint.constant;
}

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.separatorView.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    if (self.messageLabel.textColor != ThemeService.shared.theme.warningColor)
    {
        self.messageLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    }
    
    [self.resendButton.layer setCornerRadius:5];
    self.resendButton.clipsToBounds = YES;
    [self.resendButton setTitle:[VectorL10n retry] forState:UIControlStateNormal];
    self.resendButton.backgroundColor = ThemeService.shared.theme.tintColor;
    
    UIImage *image = [[UIImage imageNamed:@"room_context_menu_delete"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.deleteButton setImage:image forState:UIControlStateNormal];
    self.deleteButton.tintColor = ThemeService.shared.theme.warningColor;
    
    self.unsentMessagesTitleLabel.font = ThemeService.shared.theme.fonts.footnoteSB;
    self.unsentMessagesTitleLabel.textColor = ThemeService.shared.theme.colors.primaryContent;
    self.unsentMessagesInfoLabel.font = ThemeService.shared.theme.fonts.footnote;
    self.unsentMessagesInfoLabel.textColor = ThemeService.shared.theme.colors.secondaryContent;
    self.unsentMessagesContentView.backgroundColor = ThemeService.shared.theme.colors.background;
    
    self.unsentErrorLabel.font = ThemeService.shared.theme.fonts.subheadline;
    self.unsentErrorLabel.textColor = ThemeService.shared.theme.colors.primaryContent;
    self.unsentErrorContainer.backgroundColor = ThemeService.shared.theme.colors.background;
}

#pragma mark -

- (IBAction)onCancelSendingPressed:(id)sender
{
    void (^onCancelLinkPressed)(void) = objc_getAssociatedObject(self.deleteButton, "onCancelLinkPressed");
    if (onCancelLinkPressed)
    {
        onCancelLinkPressed ();
    }
}

- (IBAction)onResendMessagesPressed:(id)sender
{
    void (^onResendLinkPressed)(void) = objc_getAssociatedObject(self.resendButton, "onResendLinkPressed");
    if (onResendLinkPressed)
    {
        onResendLinkPressed();
    }
}

- (void)displayUnsentMessagesNotification:(NSString*)notification withResendLink:(void (^)(void))onResendLinkPressed andCancelLink:(void (^)(void))onCancelLinkPressed andIconTapGesture:(void (^)(void))onIconTapGesture
{
    [self reset];
    
    if (onResendLinkPressed && onCancelLinkPressed)
    {
        self.unsentMessagesContentView.hidden = NO;
        self.unsentMessagesTitleLabel.text = notification;
        self.unsentMessagesInfoLabel.text = VectorL10n.roomUnsentMessagesTapMessage;
        
        objc_setAssociatedObject(self.resendButton, "onResendLinkPressed", [onResendLinkPressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self.deleteButton, "onCancelLinkPressed", [onCancelLinkPressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [self checkHeight:YES];
}

- (void)displayUnsentMessageError:(NSError *)error
{
    if (self.unsentMessagesContentView.isHidden)
    {
        return;
    }
    
    if ([MXError isMXError:error])
    {
        MXError *mxError = [[MXError alloc] initWithNSError:error];
        self.unsentErrorLabel.text = mxError.error;
    }
    else
    {
        NSHTTPURLResponse *response = [MXHTTPOperation urlResponseFromError:error];
        if (response)
        {
            // This provides a more friendly message than using the localizedDescription directly.
            NSString *localizedDescription = [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode];
            self.unsentErrorLabel.text = [VectorL10n roomUnsentMessageErrorNetwork:localizedDescription];
        }
        else if ([error.domain isEqualToString:AVFoundationErrorDomain])
        {
            self.unsentErrorLabel.text = [VectorL10n roomUnsentMessageErrorEncoding:error.localizedDescription];
        }
        else
        {
            self.unsentErrorLabel.text = error.localizedDescription;
        }
    }
    
    self.unsentErrorContainer.hidden = NO;
    
    [self checkHeight:YES];
}

- (void)hideUnsentMessageError
{
    self.unsentErrorContainer.hidden = YES;
    self.unsentErrorLabel.text = nil;
    
    [self checkHeight:YES];
}

- (void)displayNetworkErrorNotification:(NSString*)labelText
{
    [self reset];
    
    if (labelText.length)
    {
        self.iconImageView.image = [UIImage imageNamed:@"error"];
        self.iconImageView.tintColor = ThemeService.shared.theme.noticeColor;
        self.messageLabel.text = labelText;
        self.messageLabel.textColor = ThemeService.shared.theme.warningColor;
        
        self.iconImageView.hidden = NO;
        self.messageLabel.hidden = NO;
    }

    [self checkHeight:YES];
}

- (void)displayRoomReplacementWithRoomLinkTappedHandler:(void (^)(void))onRoomReplacementLinkTapped
{
    [self reset];
    
    if (onRoomReplacementLinkTapped)
    {
        CGFloat fontSize = 15.0f;
        
        objc_setAssociatedObject(self.messageTextView, "onRoomReplacementLinkTapped", [onRoomReplacementLinkTapped copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        NSDictionary *roomReplacementReasonAttributes = @{
                                                          NSFontAttributeName : [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold]
                                                          };
        
        NSDictionary *roomLinkAttributes = @{
                                             NSFontAttributeName : [UIFont systemFontOfSize:fontSize],
                                             NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
                                             NSLinkAttributeName : @"onRoomReplacementLinkTapped",
                                             };
        
        NSMutableAttributedString *roomReplacementAttributedString = [NSMutableAttributedString new];
        
        NSString *roomReplacementReasonString = [NSString stringWithFormat:@"%@\n", [VectorL10n roomReplacementInformation]];
        
        NSAttributedString *roomReplacementReasonAttributedString = [[NSAttributedString alloc] initWithString:roomReplacementReasonString attributes:roomReplacementReasonAttributes];
        
                                                 NSString *roomLinkString = [VectorL10n roomReplacementLink];
        NSAttributedString *roomLinkAttributedString = [[NSAttributedString alloc] initWithString:roomLinkString attributes:roomLinkAttributes];
        
        [roomReplacementAttributedString appendAttributedString:roomReplacementReasonAttributedString];
        [roomReplacementAttributedString appendAttributedString:roomLinkAttributedString];
        
        NSRange wholeStringRange = NSMakeRange(0, roomReplacementAttributedString.length);
        [roomReplacementAttributedString addAttribute:NSForegroundColorAttributeName value:ThemeService.shared.theme.textPrimaryColor range:wholeStringRange];
        
        self.messageTextView.attributedText = roomReplacementAttributedString;
    }
    else
    {
        self.messageTextView.text = [VectorL10n roomReplacementInformation];
    }
    
    self.messageTextView.tintColor = ThemeService.shared.theme.textPrimaryColor;
    self.messageTextView.hidden = NO;
    self.messageTextView.backgroundColor = [UIColor clearColor];
    
    self.iconImageView.image = [UIImage imageNamed:@"error"];
    self.iconImageView.tintColor = ThemeService.shared.theme.noticeColor;
    self.iconImageView.hidden = NO;
    
    [self checkHeight:YES];
}

- (void)showResourceLimitExceededError:(NSDictionary *)errorDict onAdminContactTapped:(void (^)(NSURL *adminContact))onAdminContactTapped
{
    // Parse error data
    NSString *limitType, *adminContactString;

    MXJSONModelSetString(limitType, errorDict[kMXErrorResourceLimitExceededLimitTypeKey]);
    MXJSONModelSetString(adminContactString, errorDict[kMXErrorResourceLimitExceededAdminContactKey]);

    [self showResourceLimit:limitType adminContactString:adminContactString hardLimit:YES onAdminContactTapped:(void (^)(NSURL *adminContact))onAdminContactTapped];
}

- (void)showResourceUsageLimitNotice:(MXServerNoticeContent *)usageLimit onAdminContactTapped:(void (^)(NSURL *))onAdminContactTapped
{
    [self showResourceLimit:usageLimit.limitType adminContactString:usageLimit.adminContact hardLimit:NO onAdminContactTapped:onAdminContactTapped];
}

- (void)showResourceLimit:(NSString *)limitType adminContactString:(NSString *)adminContactString hardLimit:(BOOL)hardLimit onAdminContactTapped:(void (^)(NSURL *adminContact))onAdminContactTapped
{
    [self reset];

    CGFloat fontSize = 15;

    NSURL *adminContact;
    if (adminContactString)
    {
        adminContact = [NSURL URLWithString:adminContactString];
    }

    // Build the message content
    NSMutableString *message = [NSMutableString new];
    NSAttributedString *message2;
    if (hardLimit)
    {
        // Reuse MatrixKit as is for the beginning of hardLimit
        if ([limitType isEqualToString:kMXErrorResourceLimitExceededLimitTypeMonthlyActiveUserValue])
        {
            [message appendString:[MatrixKitL10n loginErrorResourceLimitExceededMessageMonthlyActiveUser]];
        }
        else
        {
            [message appendString:[MatrixKitL10n loginErrorResourceLimitExceededMessageDefault]];
        }
    }
    else
    {
        if ([limitType isEqualToString:kMXErrorResourceLimitExceededLimitTypeMonthlyActiveUserValue])
        {
            [message appendString:[VectorL10n roomResourceUsageLimitReachedMessage1MonthlyActiveUser]];
        }
        else
        {
            [message appendString:[VectorL10n roomResourceUsageLimitReachedMessage1Default]];
        }
        
        message2 = [[NSAttributedString alloc] initWithString:[VectorL10n roomResourceUsageLimitReachedMessage2]
                                                   attributes:@{
                                                       NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize],
                                                       NSForegroundColorAttributeName: ThemeService.shared.theme.backgroundColor
                                                   }];
    }

    NSDictionary *attributes = @{
                                 NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
                                 NSForegroundColorAttributeName: ThemeService.shared.theme.backgroundColor
                                 };

    NSDictionary *messageContact2LinkAttributes;
    if (adminContact && onAdminContactTapped)
    {
        void (^onAdminContactTappedLink)(void) = ^() {
            onAdminContactTapped(adminContact);
        };

        objc_setAssociatedObject(self.messageTextView, "onAdminContactTappedLink", [onAdminContactTappedLink copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        messageContact2LinkAttributes = @{
                                             NSFontAttributeName : [UIFont systemFontOfSize:fontSize],
                                             NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
                                             NSLinkAttributeName : @"onAdminContactTappedLink",
                                             };
    }
    else
    {
        messageContact2LinkAttributes = attributes;
    }

    NSAttributedString *messageContact1 = [[NSAttributedString alloc] initWithString:[VectorL10n roomResourceLimitExceededMessageContact1] attributes:attributes];
    NSAttributedString *messageContact2Link =  [[NSAttributedString alloc] initWithString:[VectorL10n roomResourceLimitExceededMessageContact2Link] attributes:messageContact2LinkAttributes];
    NSAttributedString *messageContact3;
    if (hardLimit)
    {
        messageContact3 = [[NSAttributedString alloc] initWithString:[VectorL10n roomResourceLimitExceededMessageContact3] attributes:attributes];
    }
    else
    {
        messageContact3 = [[NSAttributedString alloc] initWithString:[VectorL10n roomResourceUsageLimitReachedMessageContact3] attributes:attributes];
    }

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:message attributes:attributes];
    if (message2)
    {
        [attributedText appendAttributedString:message2];
    }
    [attributedText appendAttributedString:messageContact1];
    [attributedText appendAttributedString:messageContact2Link];
    [attributedText appendAttributedString:messageContact3];

    self.messageTextView.attributedText = attributedText;
    self.messageTextView.tintColor = ThemeService.shared.theme.backgroundColor;
    self.messageTextView.hidden = NO;

    if (hardLimit)
    {
        self.backgroundColor = ThemeService.shared.theme.warningColor;
        self.messageTextView.backgroundColor = ThemeService.shared.theme.warningColor;
    }
    else
    {
        self.backgroundColor = ThemeService.shared.riotColorCuriousBlue;
        self.messageTextView.backgroundColor = ThemeService.shared.riotColorCuriousBlue;
    }

    // Hide the separator to display correctly the banner
    self.separatorView.hidden = YES;

    [self checkHeight:YES];
}

- (void)reset
{
    self.separatorView.hidden = NO;
    self.unsentMessagesContentView.hidden = YES;

    self.backgroundColor = UIColor.clearColor;

    [self resetIcon];
    [self resetMessage];
}

- (void)resetIcon
{
    self.iconImageView.hidden = YES;
    
    // Remove all gesture recognizers
    while (self.iconImageView.gestureRecognizers.count)
    {
        [self.iconImageView removeGestureRecognizer:self.iconImageView.gestureRecognizers[0]];
    }
    self.iconImageView.userInteractionEnabled = NO;
    
    objc_removeAssociatedObjects(self.iconImageView);
}

- (void)resetMessage
{
    self.messageLabel.hidden = YES;
    
    [self.messageTextView resignFirstResponder];
    self.messageTextView.hidden = YES;
    
    self.messageLabel.textColor = ThemeService.shared.theme.textSecondaryColor;

    objc_removeAssociatedObjects(self.messageTextView);
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    if ([[URL absoluteString] isEqualToString:@"onResendLink"])
    {
        void (^onResendLinkPressed)(void) = objc_getAssociatedObject(self.messageTextView, "onResendLinkPressed");
        if (onResendLinkPressed)
        {
            onResendLinkPressed ();
        }
        
        return NO;
    }
    else if ([[URL absoluteString] isEqualToString:@"onCancelLink"])
    {
        void (^onCancelLinkPressed)(void) = objc_getAssociatedObject(self.messageTextView, "onCancelLinkPressed");
        if (onCancelLinkPressed)
        {
            onCancelLinkPressed ();
        }

        return NO;
    }
    else if ([[URL absoluteString] isEqualToString:@"onOngoingConferenceCallWithVoicePressed"])
    {
        void (^onOngoingConferenceCallPressed)(BOOL) = objc_getAssociatedObject(self.messageTextView, "onOngoingConferenceCallPressed");
        if (onOngoingConferenceCallPressed)
        {
            onOngoingConferenceCallPressed(NO);
        }

        return NO;
    }
    else if ([[URL absoluteString] isEqualToString:@"onOngoingConferenceCallWithVideoPressed"])
    {
        void (^onOngoingConferenceCallPressed)(BOOL) = objc_getAssociatedObject(self.messageTextView, "onOngoingConferenceCallPressed");
        if (onOngoingConferenceCallPressed)
        {
            onOngoingConferenceCallPressed(YES);
        }

        return NO;
    }
    else if ([[URL absoluteString] isEqualToString:@"onOngoingConferenceCallClosePressed"])
    {
        void (^onOngoingConferenceCallClosePressed)(BOOL) = objc_getAssociatedObject(self.messageTextView, "onOngoingConferenceCallClosePressed");
        if (onOngoingConferenceCallClosePressed)
        {
            onOngoingConferenceCallClosePressed(YES);
        }

        return NO;
    }
    else if ([[URL absoluteString] isEqualToString:@"onRoomReplacementLinkTapped"])
    {
        void (^onRoomReplacementLinkTapped)(void) = objc_getAssociatedObject(self.messageTextView, "onRoomReplacementLinkTapped");
        if (onRoomReplacementLinkTapped)
        {
            onRoomReplacementLinkTapped();
        }
        
        return NO;
    }
    else if ([[URL absoluteString] isEqualToString:@"onAdminContactTappedLink"])
    {
        void (^onAdminContactTappedLink)(void) = objc_getAssociatedObject(self.messageTextView, "onAdminContactTappedLink");
        if (onAdminContactTappedLink)
        {
            onAdminContactTappedLink();
        }

        return NO;
    }
    
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate

- (void)onIconTap:(UITapGestureRecognizer*)sender
{
    void (^onIconTapGesture)(void) = objc_getAssociatedObject(self.iconImageView, "onIconTapGesture");
    if (onIconTapGesture)
    {
        onIconTapGesture ();
    }
}

@end
