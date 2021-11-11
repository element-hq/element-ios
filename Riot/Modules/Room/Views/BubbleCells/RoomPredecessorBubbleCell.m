/*
 Copyright 2018 New Vector Ltd
 
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


#import "RoomPredecessorBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#pragma mark - Defines & Constants

static CGFloat const kCustomBackgroundCornerRadius = 5.0;

#pragma mark - Private Interface

@interface RoomPredecessorBubbleCell()

@property (weak, nonatomic) IBOutlet UIView *customBackgroundView;

@end

#pragma mark - Implementation

@implementation RoomPredecessorBubbleCell

#pragma mark - View life cycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Disable text selection and link interaction
    self.messageTextView.selectable = NO;
    self.customBackgroundView.layer.masksToBounds = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.customBackgroundView.layer.cornerRadius = kCustomBackgroundCornerRadius;
}

#pragma mark - Superclass Overrides

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.messageTextView.tintColor = ThemeService.shared.theme.textPrimaryColor;
    self.customBackgroundView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
}

@end
