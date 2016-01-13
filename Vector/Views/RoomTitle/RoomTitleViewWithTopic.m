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

#import "RoomTitleViewWithTopic.h"

#import "VectorDesignValues.h"

#import "MXRoom+Vector.h"

@implementation RoomTitleViewWithTopic

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomTitleViewWithTopic class])
                          bundle:[NSBundle bundleForClass:[RoomTitleViewWithTopic class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.displayNameTextField.textColor = VECTOR_TEXT_BLACK_COLOR;
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    if (self.mxRoom)
    {
        self.displayNameTextField.text = self.mxRoom.vectorDisplayname;
    }
}

@end
