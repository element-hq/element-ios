/*
Copyright 2019-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
    
    UIImage *image = [AssetImages.roomContextMenuDelete.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.deleteButton setImage:image forState:UIControlStateNormal];
    self.deleteButton.tintColor = ThemeService.shared.theme.warningColor;
    
    self.unsentMessageLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.unsentMessagesContentView.backgroundColor = ThemeService.shared.theme.backgroundColor;
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
        self.unsentMessageLabel.text = notification;
        
        objc_setAssociatedObject(self.resendButton, "onResendLinkPressed", [onResendLinkPressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self.deleteButton, "onCancelLinkPressed", [onCancelLinkPressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [self checkHeight:YES];
}

- (void)displayNetworkErrorNotification:(NSString*)labelText
{
    [self reset];
    
    if (labelText.length)
    {
        self.iconImageView.image = AssetImages.error.image;
        self.iconImageView.tintColor = ThemeService.shared.theme.noticeColor;
        self.messageLabel.text = labelText;
        self.messageLabel.textColor = ThemeService.shared.theme.warningColor;
        
        self.iconImageView.hidden = NO;
        self.messageLabel.hidden = NO;
    }

    [self checkHeight:YES];
}

- (void)displayTypingNotification:(NSString*)labelText
{
    [self reset];
    
    if (labelText.length)
    {
        self.iconImageView.image = AssetImages.typing.image;
        self.iconImageView.tintColor = ThemeService.shared.theme.tintColor;
        self.messageLabel.text = labelText;
        
        self.iconImageView.hidden = NO;
        self.messageLabel.hidden = NO;
    }

    [self checkHeight:YES];
}

- (void)displayOngoingConferenceCall:(void (^)(BOOL))onOngoingConferenceCallPressed onClosePressed:(void (^)(void))onOngoingConferenceCallClosePressed
{
    [self reset];

    objc_setAssociatedObject(self.messageTextView, "onOngoingConferenceCallPressed", [onOngoingConferenceCallPressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Build the string to display in the banner
    NSString *onGoingConferenceCall;

    if (!onOngoingConferenceCallClosePressed)
    {
        onGoingConferenceCall = [VectorL10n roomOngoingConferenceCall:[VectorL10n voice] :[VectorL10n video]];
    }
    else
    {
        // Display the banner with a "Close it" string
        objc_setAssociatedObject(self.messageTextView, "onOngoingConferenceCallClosePressed", [onOngoingConferenceCallClosePressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        onGoingConferenceCall = [VectorL10n roomOngoingConferenceCallWithClose:[VectorL10n voice] :[VectorL10n video] :[VectorL10n roomOngoingConferenceCallClose]];
    }

    NSMutableAttributedString *onGoingConferenceCallAttibutedString = [[NSMutableAttributedString alloc] initWithString:onGoingConferenceCall];

    // Add a link on the "voice" string
    NSRange voiceRange = [onGoingConferenceCall rangeOfString:[VectorL10n voice]];
    [onGoingConferenceCallAttibutedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:voiceRange];
    [onGoingConferenceCallAttibutedString addAttribute:NSLinkAttributeName value:@"onOngoingConferenceCallWithVoicePressed" range:voiceRange];

    // Add a link on the "video" string
    NSRange videoRange = [onGoingConferenceCall rangeOfString:[VectorL10n video]];
    [onGoingConferenceCallAttibutedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:videoRange];
    [onGoingConferenceCallAttibutedString addAttribute:NSLinkAttributeName value:@"onOngoingConferenceCallWithVideoPressed" range:videoRange];

    // Add a link on the "Close" string
    if (onOngoingConferenceCallClosePressed)
    {
        NSRange closeRange = [onGoingConferenceCall rangeOfString:[VectorL10n roomOngoingConferenceCallClose]];
        [onGoingConferenceCallAttibutedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:closeRange];
        [onGoingConferenceCallAttibutedString addAttribute:NSLinkAttributeName value:@"onOngoingConferenceCallClosePressed" range:closeRange];
    }

    // Display the string in white on pink red
    NSRange wholeString = NSMakeRange(0, onGoingConferenceCallAttibutedString.length);
    [onGoingConferenceCallAttibutedString addAttribute:NSForegroundColorAttributeName value:ThemeService.shared.theme.backgroundColor range:wholeString];
    [onGoingConferenceCallAttibutedString addAttribute:NSBackgroundColorAttributeName value:ThemeService.shared.theme.tintColor range:wholeString];
    [onGoingConferenceCallAttibutedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:wholeString];

    self.messageTextView.attributedText = onGoingConferenceCallAttibutedString;
    self.messageTextView.tintColor = ThemeService.shared.theme.backgroundColor;
    self.messageTextView.hidden = NO;

    self.backgroundColor = ThemeService.shared.theme.tintColor;
    self.messageTextView.backgroundColor = ThemeService.shared.theme.tintColor;

    // Hide the separator to display correctly the red pink conf call banner
    self.separatorView.hidden = YES;

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
    
    self.iconImageView.image = AssetImages.error.image;
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
            [message appendString:[VectorL10n loginErrorResourceLimitExceededMessageMonthlyActiveUser]];
        }
        else
        {
            [message appendString:[VectorL10n loginErrorResourceLimitExceededMessageDefault]];
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

    [self checkHeight:YES];
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
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
#pragma clang diagnostic pop

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
