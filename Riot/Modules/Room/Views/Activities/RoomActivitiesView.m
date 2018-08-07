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

#import "RoomActivitiesView.h"

#import "RiotDesignValues.h"

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
    
    self.separatorView.backgroundColor = kRiotSecondaryBgColor;
    if (self.messageLabel.textColor != kRiotColorPinkRed)
    {
        self.messageLabel.textColor = kRiotSecondaryTextColor;
    }
}

#pragma mark -

- (void)displayUnsentMessagesNotification:(NSString*)notification withResendLink:(void (^)(void))onResendLinkPressed andCancelLink:(void (^)(void))onCancelLinkPressed andIconTapGesture:(void (^)(void))onIconTapGesture
{
    [self reset];

    if (onResendLinkPressed && onCancelLinkPressed)
    {
        NSString *resendLink = NSLocalizedStringFromTable(@"room_prompt_resend", @"Vector", nil);
        NSString *cancelLink = NSLocalizedStringFromTable(@"room_prompt_cancel", @"Vector", nil);

        NSString *notif = [NSString stringWithFormat:notification, resendLink, cancelLink];
        NSMutableAttributedString *tappableNotif = [[NSMutableAttributedString alloc] initWithString:notif];
        
        objc_setAssociatedObject(self.messageTextView, "onResendLinkPressed", [onResendLinkPressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self.messageTextView, "onCancelLinkPressed", [onCancelLinkPressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        NSRange range = [notif rangeOfString:resendLink];
        [tappableNotif addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
        [tappableNotif addAttribute:NSLinkAttributeName value:@"onResendLink" range:range];

        range = [notif rangeOfString:cancelLink];
        [tappableNotif addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
        [tappableNotif addAttribute:NSLinkAttributeName value:@"onCancelLink" range:range];
        
        NSRange wholeString = NSMakeRange(0, tappableNotif.length);
        [tappableNotif addAttribute:NSForegroundColorAttributeName value:kRiotColorPinkRed range:wholeString];
        [tappableNotif addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:wholeString];
        
        self.messageTextView.attributedText = tappableNotif;
        self.messageTextView.tintColor = kRiotColorPinkRed;
        self.messageTextView.hidden = NO;
        self.messageTextView.backgroundColor = [UIColor clearColor];
    }
    else
    {
        self.messageLabel.text = notification;
        self.messageLabel.textColor = kRiotColorPinkRed;
        self.messageLabel.hidden = NO;
    }
    
    self.iconImageView.image = [UIImage imageNamed:@"error"];
    self.iconImageView.hidden = NO;
    
    if (onIconTapGesture)
    {
        objc_setAssociatedObject(self.iconImageView, "onIconTapGesture", [onIconTapGesture copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // Listen to icon tap
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onIconTap:)];
        [tapGesture setNumberOfTouchesRequired:1];
        [tapGesture setNumberOfTapsRequired:1];
        [tapGesture setDelegate:self];
        [self.iconImageView addGestureRecognizer:tapGesture];
        self.iconImageView.userInteractionEnabled = YES;
    }

    [self checkHeight:YES];
}

- (void)displayNetworkErrorNotification:(NSString*)labelText
{
    [self reset];
    
    if (labelText.length)
    {
        self.iconImageView.image = [UIImage imageNamed:@"error"];
        self.messageLabel.text = labelText;
        self.messageLabel.textColor = kRiotColorPinkRed;
        
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
        self.iconImageView.image = [UIImage imageNamed:@"typing"];
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
        onGoingConferenceCall = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_ongoing_conference_call", @"Vector", nil),
                                 NSLocalizedStringFromTable(@"voice", @"Vector", nil),
                                 NSLocalizedStringFromTable(@"video", @"Vector", nil)];
    }
    else
    {
        // Display the banner with a "Close it" string
        objc_setAssociatedObject(self.messageTextView, "onOngoingConferenceCallClosePressed", [onOngoingConferenceCallClosePressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        onGoingConferenceCall = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_ongoing_conference_call_with_close", @"Vector", nil),
                                 NSLocalizedStringFromTable(@"voice", @"Vector", nil),
                                 NSLocalizedStringFromTable(@"video", @"Vector", nil),
                                 NSLocalizedStringFromTable(@"room_ongoing_conference_call_close", @"Vector", nil)];
    }

    NSMutableAttributedString *onGoingConferenceCallAttibutedString = [[NSMutableAttributedString alloc] initWithString:onGoingConferenceCall];

    // Add a link on the "voice" string
    NSRange voiceRange = [onGoingConferenceCall rangeOfString:NSLocalizedStringFromTable(@"voice", @"Vector", nil)];
    [onGoingConferenceCallAttibutedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:voiceRange];
    [onGoingConferenceCallAttibutedString addAttribute:NSLinkAttributeName value:@"onOngoingConferenceCallWithVoicePressed" range:voiceRange];

    // Add a link on the "video" string
    NSRange videoRange = [onGoingConferenceCall rangeOfString:NSLocalizedStringFromTable(@"video", @"Vector", nil)];
    [onGoingConferenceCallAttibutedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:videoRange];
    [onGoingConferenceCallAttibutedString addAttribute:NSLinkAttributeName value:@"onOngoingConferenceCallWithVideoPressed" range:videoRange];

    // Add a link on the "Close" string
    if (onOngoingConferenceCallClosePressed)
    {
        NSRange closeRange = [onGoingConferenceCall rangeOfString:NSLocalizedStringFromTable(@"room_ongoing_conference_call_close", @"Vector", nil)];
        [onGoingConferenceCallAttibutedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:closeRange];
        [onGoingConferenceCallAttibutedString addAttribute:NSLinkAttributeName value:@"onOngoingConferenceCallClosePressed" range:closeRange];
    }

    // Display the string in white on pink red
    NSRange wholeString = NSMakeRange(0, onGoingConferenceCallAttibutedString.length);
    [onGoingConferenceCallAttibutedString addAttribute:NSForegroundColorAttributeName value:kRiotPrimaryBgColor range:wholeString];
    [onGoingConferenceCallAttibutedString addAttribute:NSBackgroundColorAttributeName value:kRiotColorPinkRed range:wholeString];
    [onGoingConferenceCallAttibutedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:wholeString];

    self.messageTextView.attributedText = onGoingConferenceCallAttibutedString;
    self.messageTextView.tintColor = kRiotPrimaryBgColor;
    self.messageTextView.hidden = NO;

    self.backgroundColor = kRiotColorPinkRed;
    self.messageTextView.backgroundColor = kRiotColorPinkRed;

    // Hide the separator to display correctly the red pink conf call banner
    self.separatorView.hidden = YES;

    [self checkHeight:YES];
}

- (void)displayScrollToBottomIcon:(NSUInteger)newMessagesCount onIconTapGesture:(void (^)(void))onIconTapGesture
{
    if (newMessagesCount)
    {
        [self reset];
        
        self.iconImageView.image = [UIImage imageNamed:@"newmessages"];
        
        NSString *notification;
        if (newMessagesCount > 1)
        {
            notification = NSLocalizedStringFromTable(@"room_new_messages_notification", @"Vector", nil);
        }
        else
        {
            notification = NSLocalizedStringFromTable(@"room_new_message_notification", @"Vector", nil);
        }
        self.messageLabel.text = [NSString stringWithFormat:notification, newMessagesCount];
        self.messageLabel.textColor = kRiotColorPinkRed;
        self.messageLabel.hidden = NO;
    }
    else
    {
        // We keep the current message if any
        [self resetIcon];
        
        self.iconImageView.image = [UIImage imageNamed:@"scrolldown"];
    }
    self.iconImageView.hidden = NO;
    
    if (onIconTapGesture)
    {
        objc_setAssociatedObject(self.iconImageView, "onIconTapGesture", [onIconTapGesture copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // Listen to icon tap
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onIconTap:)];
        [tapGesture setNumberOfTouchesRequired:1];
        [tapGesture setNumberOfTapsRequired:1];
        [tapGesture setDelegate:self];
        [self.iconImageView addGestureRecognizer:tapGesture];
        self.iconImageView.userInteractionEnabled = YES;
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
        
        NSString *roomReplacementReasonString = [NSString stringWithFormat:@"%@\n", NSLocalizedStringFromTable(@"room_replacement_information", @"Vector", nil)];
        
        NSAttributedString *roomReplacementReasonAttributedString = [[NSAttributedString alloc] initWithString:roomReplacementReasonString attributes:roomReplacementReasonAttributes];
        
        NSString *roomLinkString = NSLocalizedStringFromTable(@"room_replacement_link", @"Vector", nil);
        NSAttributedString *roomLinkAttributedString = [[NSAttributedString alloc] initWithString:roomLinkString attributes:roomLinkAttributes];
        
        [roomReplacementAttributedString appendAttributedString:roomReplacementReasonAttributedString];
        [roomReplacementAttributedString appendAttributedString:roomLinkAttributedString];
        
        NSRange wholeStringRange = NSMakeRange(0, roomReplacementAttributedString.length);
        [roomReplacementAttributedString addAttribute:NSForegroundColorAttributeName value:kRiotPrimaryTextColor range:wholeStringRange];
        
        self.messageTextView.attributedText = roomReplacementAttributedString;
    }
    else
    {
        self.messageTextView.text = NSLocalizedStringFromTable(@"room_replacement_information", @"Vector", nil);
    }
    
    self.messageTextView.tintColor = kRiotPrimaryTextColor;
    self.messageTextView.hidden = NO;
    self.messageTextView.backgroundColor = [UIColor clearColor];
    
    self.iconImageView.image = [UIImage imageNamed:@"error"];
    self.iconImageView.hidden = NO;
    
    [self checkHeight:YES];
}

- (void)reset
{
    self.separatorView.hidden = NO;

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
    
    self.messageLabel.textColor = kRiotSecondaryTextColor;

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
