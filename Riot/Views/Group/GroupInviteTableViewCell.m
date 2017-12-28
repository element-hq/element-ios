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

#import "GroupInviteTableViewCell.h"

#import "RiotDesignValues.h"

#pragma mark - Constant definitions

NSString *const kGroupInviteTableViewCellPreviewButtonPressed = @"kGroupInviteTableViewCellPreviewButtonPressed";
NSString *const kGroupInviteTableViewCellDeclineButtonPressed = @"kGroupInviteTableViewCellDeclineButtonPressed";

NSString *const kGroupInviteTableViewCellRoomKey = @"kGroupInviteTableViewCellRoomKey";

@implementation GroupInviteTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.leftButton.layer setCornerRadius:5];
    self.leftButton.clipsToBounds = YES;
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateNormal];
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateHighlighted];
    [self.leftButton addTarget:self action:@selector(onDeclinePressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.rightButton.layer setCornerRadius:5];
    self.rightButton.clipsToBounds = YES;
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"preview", @"Vector", nil) forState:UIControlStateNormal];
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"preview", @"Vector", nil) forState:UIControlStateHighlighted];
    [self.rightButton addTarget:self action:@selector(onPreviewPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.noticeBadgeView.layer setCornerRadius:10];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.leftButton.backgroundColor = kRiotColorBlue;
    self.rightButton.backgroundColor = kRiotColorBlue;
    
    self.noticeBadgeView.backgroundColor = kRiotColorPinkRed;
}

- (void)onDeclinePressed:(id)sender
{
    if (self.delegate)
    {
        MXGroup *group = groupCellData.group;
        
        if (group)
        {
            [self.delegate cell:self didRecognizeAction:kGroupInviteTableViewCellDeclineButtonPressed userInfo:@{kGroupInviteTableViewCellRoomKey:group}];
        }
    }
}

- (void)onPreviewPressed:(id)sender
{
    if (self.delegate)
    {
        MXGroup *group = groupCellData.group;
        
        if (group)
        {
            [self.delegate cell:self didRecognizeAction:kGroupInviteTableViewCellPreviewButtonPressed userInfo:@{kGroupInviteTableViewCellRoomKey:group}];
        }
    }
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
}

@end
