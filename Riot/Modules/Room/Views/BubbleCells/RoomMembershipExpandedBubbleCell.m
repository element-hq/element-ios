/*
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

#import "RoomMembershipExpandedBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "RoomBubbleCellData.h"

NSString *const kRoomMembershipExpandedBubbleCellTapOnCollapseButton = @"kRoomMembershipExpandedBubbleCellTapOnCollapseButton";

@implementation RoomMembershipExpandedBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSString* title = [VectorL10n collapse];
    [self.collapseButton setTitle:title forState:UIControlStateNormal];
    [self.collapseButton setTitle:title forState:UIControlStateHighlighted];
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.separatorView.backgroundColor = ThemeService.shared.theme.lineBreakColor;
    
    [self.collapseButton setTintColor:ThemeService.shared.theme.tintColor];
    self.collapseButton.titleLabel.font = [UIFont systemFontOfSize:14];
}

- (IBAction)onCollapseButtonTap:(id)sender
{
    if (self.delegate)
    {
        [self.delegate cell:self didRecognizeAction:kRoomMembershipExpandedBubbleCellTapOnCollapseButton userInfo:nil];
    }
}

@end
