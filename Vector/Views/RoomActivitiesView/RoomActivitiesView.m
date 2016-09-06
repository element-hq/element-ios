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

#import "RoomActivitiesView.h"

#import "VectorDesignValues.h"

#import <objc/runtime.h>

@implementation RoomActivitiesView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomActivitiesView class])
                          bundle:[NSBundle bundleForClass:[RoomActivitiesView class]]];
}

- (CGFloat)height
{
    return self.mainHeightConstraint.constant;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.separatorView.backgroundColor = kVectorColorLightGrey;
    self.messageLabel.textColor = kVectorTextColorGray;
    
    // Adjust text view
    // Remove the container inset: this operation impacts only the vertical margin.
    // Reset textContainer.lineFragmentPadding to remove horizontal margin.
    self.messageTextView.textContainerInset = UIEdgeInsetsZero;
    self.messageTextView.textContainer.lineFragmentPadding = 0;
}

- (void)displayUnsentMessagesNotificationWithResendLink:(void (^)(void))onResendLinkPressed andIconTapGesture:(void (^)(void))onIconTapGesture
{
    [self reset];
    
    NSString *notification = NSLocalizedStringFromTable(@"room_unsent_messages_notification", @"Vector", nil);
    
    if (onResendLinkPressed)
    {
        NSString *resendLink = NSLocalizedStringFromTable(@"room_prompt_resend", @"Vector", nil);
        
        NSMutableAttributedString *tappableNotif = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", notification, resendLink]];
        
        objc_setAssociatedObject(self.messageTextView, "onResendLinkPressed", [onResendLinkPressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        NSRange range = NSMakeRange(notification.length + 1, resendLink.length);
        [tappableNotif addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];
        [tappableNotif addAttribute:NSLinkAttributeName value:@"onResendLink" range:range];
        
        NSRange wholeString = NSMakeRange(0, tappableNotif.length);
        [tappableNotif addAttribute:NSForegroundColorAttributeName value:kVectorColorPinkRed range:wholeString];
        [tappableNotif addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:wholeString];
        
        self.messageTextView.attributedText = tappableNotif;
        self.messageTextView.tintColor = kVectorColorPinkRed;
        self.messageTextView.hidden = NO;
    }
    else
    {
        self.messageLabel.text = notification;
        self.messageLabel.textColor = kVectorColorPinkRed;
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
}

- (void)displayNetworkErrorNotification:(NSString*)labelText
{
    [self reset];
    
    if (labelText.length)
    {
        self.iconImageView.image = [UIImage imageNamed:@"error"];
        self.messageLabel.text = labelText;
        self.messageLabel.textColor = kVectorColorPinkRed;
        
        self.iconImageView.hidden = NO;
        self.messageLabel.hidden = NO;
    }
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
}

- (void)displayOngoingConferenceCall:(void (^)(BOOL))onOngoingConferenceCallPressed
{
    [self reset];

    objc_setAssociatedObject(self.messageTextView, "onOngoingConferenceCallPressed", [onOngoingConferenceCallPressed copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Build the string to display in the banner
    NSString *onGoingConferenceCall =
    [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_ongoing_conference_call", @"Vector", nil),
     NSLocalizedStringFromTable(@"voice", @"Vector", nil),
     NSLocalizedStringFromTable(@"video", @"Vector", nil)];

    NSMutableAttributedString *onGoingConferenceCallAttibutedString = [[NSMutableAttributedString alloc] initWithString:onGoingConferenceCall];

    // Add a link on the "voice" string
    NSRange voiceRange = [onGoingConferenceCall rangeOfString:NSLocalizedStringFromTable(@"voice", @"Vector", nil)];
    [onGoingConferenceCallAttibutedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:voiceRange];
    [onGoingConferenceCallAttibutedString addAttribute:NSLinkAttributeName value:@"onOngoingConferenceCallWithVoicePressed" range:voiceRange];

    // Add a link on the "video" string
    NSRange videoRange = [onGoingConferenceCall rangeOfString:NSLocalizedStringFromTable(@"video", @"Vector", nil)];
    [onGoingConferenceCallAttibutedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:videoRange];
    [onGoingConferenceCallAttibutedString addAttribute:NSLinkAttributeName value:@"onOngoingConferenceCallWithVideoPressed" range:videoRange];

    // Display the string in white on pink red
    NSRange wholeString = NSMakeRange(0, onGoingConferenceCallAttibutedString.length);
    [onGoingConferenceCallAttibutedString addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:wholeString];
    [onGoingConferenceCallAttibutedString addAttribute:NSBackgroundColorAttributeName value:kVectorColorPinkRed range:wholeString];
    [onGoingConferenceCallAttibutedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:wholeString];

    self.messageTextView.attributedText = onGoingConferenceCallAttibutedString;
    self.messageTextView.tintColor = UIColor.whiteColor;
    self.messageTextView.hidden = NO;

    self.backgroundColor = kVectorColorPinkRed;
    self.messageTextView.backgroundColor = kVectorColorPinkRed;
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
        self.messageLabel.textColor = kVectorColorPinkRed;
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
}

- (void)reset
{
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
    
    self.messageLabel.textColor = kVectorTextColorGray;

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
