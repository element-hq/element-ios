/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "RoomMemberActionsCell.h"

@implementation RoomMemberActionsCell

- (void)initButton:(UIButton*)button withText:(NSString*)text {
    
    button.hidden = (text.length == 0);
    
    button.layer.borderColor = button.tintColor.CGColor;
    button.layer.borderWidth = 1;
    button.layer.cornerRadius = 5;

    [button setTitle:text forState:UIControlStateNormal];
    [button setTitle:text forState:UIControlStateHighlighted];
}

- (void) setLeftButtonText:(NSString*)text {
    [self initButton:self.leftButton withText:text];
}

- (void) setRightButtonText:(NSString*)text {
    [self initButton:self.rightButton withText:text];
}

@end
