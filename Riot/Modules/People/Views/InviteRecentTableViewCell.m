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

#import "InviteRecentTableViewCell.h"

#import "AvatarGenerator.h"

#import "MXEvent.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#pragma mark - Constant definitions

NSString *const kInviteRecentTableViewCellAcceptButtonPressed = @"kInviteRecentTableViewCellAcceptButtonPressed";
NSString *const kInviteRecentTableViewCellPreviewButtonPressed = @"kInviteRecentTableViewCellPreviewButtonPressed";
NSString *const kInviteRecentTableViewCellDeclineButtonPressed = @"kInviteRecentTableViewCellDeclineButtonPressed";

NSString *const kInviteRecentTableViewCellRoomKey = @"kInviteRecentTableViewCellRoomKey";

@implementation InviteRecentTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.leftButton.layer setCornerRadius:8];
    self.leftButton.clipsToBounds = YES;
    [self.leftButton setTitle:[VectorL10n decline] forState:UIControlStateNormal];
    [self.leftButton addTarget:self action:@selector(onDeclinePressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.rightButton.layer setCornerRadius:8];
    self.rightButton.clipsToBounds = YES;
    [self.rightButton setTitle:[VectorL10n accept] forState:UIControlStateNormal];
    [self.rightButton addTarget:self action:@selector(onRightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.leftButton.backgroundColor = UIColor.clearColor;
    self.leftButton.layer.borderWidth = 1;
    self.leftButton.layer.borderColor = ThemeService.shared.theme.colors.alert.CGColor;
    self.leftButton.titleLabel.font = ThemeService.shared.theme.fonts.body;
    [self.leftButton setTitleColor:ThemeService.shared.theme.colors.alert forState:UIControlStateNormal];

    self.rightButton.backgroundColor = ThemeService.shared.theme.tintColor;
    self.rightButton.titleLabel.font = ThemeService.shared.theme.fonts.body;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self resetButtonViews];
    self.accessoryView = nil;
}

- (void)onDeclinePressed:(id)sender
{
    [self notifyDelegateWithActionIdentifier:kInviteRecentTableViewCellDeclineButtonPressed];
}

- (void)onRightButtonPressed:(id)sender
{
    [self notifyDelegateWithActionIdentifier:kInviteRecentTableViewCellAcceptButtonPressed];
}

- (void)notifyDelegateWithActionIdentifier:(NSString*)actionIdentifier
{
    if (self.delegate)
    {
        MXRoom *room = [roomCellData.mxSession roomWithRoomId:roomCellData.roomIdentifier];
        
        if (room)
        {
            [self.delegate cell:self didRecognizeAction:actionIdentifier userInfo:@{kInviteRecentTableViewCellRoomKey:room}];
        }
    }
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    [self updateViewsWithRoom:roomCellData.roomSummary showPreviewButton:NO];
}

- (void)updateViewsWithRoom:(id<MXRoomSummaryProtocol>)room showPreviewButton:(BOOL)showPreviewButton
{
    NSString *rightButtonTitle;
    
    if (!showPreviewButton)
    {
        rightButtonTitle = [VectorL10n accept];
        [self vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
    }
    else
    {
        rightButtonTitle = [VectorL10n preview];
        self.accessoryView = nil;
    }
    
    [self.rightButton setTitle:rightButtonTitle forState:UIControlStateNormal];
    
    [self updateButtonViewsWith:room];
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 105;
}

@end
