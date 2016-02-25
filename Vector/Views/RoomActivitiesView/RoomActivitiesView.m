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
}

- (void)displayUnsentMessagesNotification:(NSAttributedString*)labelText onLabelTapGesture:(void (^)(void))onLabelTapGesture
{
    [self reset];
    
    if (labelText.length)
    {
        self.iconImageView.image = [UIImage imageNamed:@"error"];
        self.messageLabel.attributedText = labelText;
        self.messageLabel.textColor = kVectorTextColorRed;
        
        self.iconImageView.hidden = NO;
        self.messageLabel.hidden = NO;
        
        if (onLabelTapGesture)
        {
            objc_setAssociatedObject(self.messageLabel, "onLabelTapGesture", [onLabelTapGesture copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            // Listen to label tap
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onLabelTap:)];
            [tapGesture setNumberOfTouchesRequired:1];
            [tapGesture setNumberOfTapsRequired:1];
            [tapGesture setDelegate:self];
            [self.messageLabel addGestureRecognizer:tapGesture];
            self.messageLabel.userInteractionEnabled = YES;
        }
    }
}

- (void)onLabelTap:(UITapGestureRecognizer*)sender
{
    void (^onLabelTapGesture)(void) = objc_getAssociatedObject(self.messageLabel, "onLabelTapGesture");
    if (onLabelTapGesture)
    {
        onLabelTapGesture ();
    }
}

- (void)displayNetworkErrorNotification:(NSString*)labelText
{
    [self reset];
    
    if (labelText.length)
    {
        self.iconImageView.image = [UIImage imageNamed:@"error"];
        self.messageLabel.text = labelText;
        self.messageLabel.textColor = kVectorTextColorRed;
        
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

- (void)reset
{
    self.iconImageView.hidden = YES;
    self.messageLabel.hidden = YES;
    
    self.messageLabel.textColor = kVectorTextColorGray;
    
    // Remove all gesture recognizer
    while (self.messageLabel.gestureRecognizers.count)
    {
        [self.messageLabel removeGestureRecognizer:self.messageLabel.gestureRecognizers[0]];
    }
    self.messageLabel.userInteractionEnabled = NO;
    
    objc_removeAssociatedObjects(self.messageLabel);
}

@end
