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

- (void)displayOngoingConferenceCall:(NSString *)labelText
{
    [self reset];

    if (labelText.length)
    {
        self.backgroundColor = kVectorColorPinkRed;

        self.iconImageView.image = [UIImage imageNamed:@"typing"];
        self.messageLabel.text = labelText;
        self.messageLabel.textColor = UIColor.whiteColor;

        self.messageLabel.hidden = NO;
    }
}

- (void)reset
{
    self.backgroundColor = UIColor.clearColor;

    self.iconImageView.hidden = YES;
    self.messageLabel.hidden = YES;
    
    [self.messageTextView resignFirstResponder];
    self.messageTextView.hidden = YES;
    
    self.messageLabel.textColor = kVectorTextColorGray;
    
    // Remove all gesture recognizers
    while (self.iconImageView.gestureRecognizers.count)
    {
        [self.iconImageView removeGestureRecognizer:self.iconImageView.gestureRecognizers[0]];
    }
    self.iconImageView.userInteractionEnabled = NO;
    
    while (self.gestureRecognizers.count)
    {
        [self removeGestureRecognizer:self.gestureRecognizers[0]];
    }
    
    objc_removeAssociatedObjects(self.iconImageView);
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
