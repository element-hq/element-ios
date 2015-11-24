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
    
    // Remove default toolbar background color
    self.backgroundColor = [UIColor whiteColor];
    
    // TODO : put this mint grey color as a resource
    self.typingImageView.backgroundColor = [UIColor colorWithRed:(98.0/256.0) green:(206.0/256.0) blue:(156.0/256.0) alpha:1.0];
    self.typingImageView.layer.cornerRadius = self.typingImageView.frame.size.height / 2; 
    
}

// update the displayed typing message.
// nil message hides the typing icon too.
- (void)updateTypingMessage:(NSString*)message
{
    if (message)
    {
        self.typingImageView.hidden = false;
        self.messageLabel.hidden = false;
        self.messageLabel.text = message;
    }
    else
    {
        self.typingImageView.hidden = true;
        self.messageLabel.hidden = true;
    }
}

@end
