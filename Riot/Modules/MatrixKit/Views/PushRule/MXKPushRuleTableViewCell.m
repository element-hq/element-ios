/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKPushRuleTableViewCell.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@implementation MXKPushRuleTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [_controlButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_pause"] forState:UIControlStateNormal];
    [_controlButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_pause"] forState:UIControlStateHighlighted];
    
    [_deleteButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_minus"] forState:UIControlStateNormal];
    [_deleteButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_minus"] forState:UIControlStateHighlighted];
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    _controlButton.backgroundColor = [UIColor clearColor];
    
    _deleteButton.backgroundColor = [UIColor clearColor];
    
    _ruleDescription.numberOfLines = 0;
}

- (void)setMxPushRule:(MXPushRule *)mxPushRule
{
    // Set the right control icon
    if (mxPushRule.enabled)
    {
        [_controlButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_pause"] forState:UIControlStateNormal];
        [_controlButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_pause"] forState:UIControlStateHighlighted];
    }
    else
    {
        [_controlButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_play"] forState:UIControlStateNormal];
        [_controlButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_play"] forState:UIControlStateHighlighted];
    }
    
    // Prepare rule description (use rule id by default)
    NSString *description = mxPushRule.ruleId;
    
    switch (mxPushRule.kind)
    {
        case MXPushRuleKindContent:
            description = mxPushRule.pattern;
            break;
        case MXPushRuleKindRoom:
        {
            MXRoom *room = [_mxSession roomWithRoomId:mxPushRule.ruleId];
            if (room)
            {
                description = [VectorL10n notificationSettingsRoomRuleTitle:room.summary.displayName];
            }
            break;
        }
        default:
            break;
    }
    
    _ruleDescription.text = description;
    
    // Delete button and rule actions are hidden for predefined rules
    if (mxPushRule.isDefault)
    {
        if (!_deleteButton.hidden)
        {
            _deleteButton.hidden = YES;
            // Adjust layout by updating constraint
            _ruleDescriptionLeftConstraint.constant -= _deleteButtonWidthConstraint.constant;
        }
        
        if (!_ruleActions.isHidden)
        {
            _ruleActions.hidden = YES;
            // Adjust layout by updating constraint
            _ruleDescriptionBottomConstraint.constant -= _ruleActionsHeightConstraint.constant;
        }
    }
    else
    {
        if (_deleteButton.hidden)
        {
            _deleteButton.hidden = NO;
            // Adjust layout by updating constraint
            _ruleDescriptionLeftConstraint.constant += _deleteButtonWidthConstraint.constant;
        }
        
        // Prepare rule actions description
        NSString *notify;
        NSString *sound = @"";
        NSString *highlight = @"";
        for (MXPushRuleAction *ruleAction in mxPushRule.actions)
        {
            if (ruleAction.actionType == MXPushRuleActionTypeDontNotify)
            {
                notify = [VectorL10n notificationSettingsNeverNotify];
                sound = @"";
                highlight = @"";
                break;
            }
            else if (ruleAction.actionType == MXPushRuleActionTypeNotify || ruleAction.actionType == MXPushRuleActionTypeCoalesce)
            {
                notify = [VectorL10n notificationSettingsAlwaysNotify];
            }
            else if (ruleAction.actionType == MXPushRuleActionTypeSetTweak)
            {
                if ([ruleAction.parameters[@"set_tweak"] isEqualToString:@"sound"])
                {
                    sound = [NSString stringWithFormat:@", %@", [VectorL10n notificationSettingsCustomSound]];
                }
                else if ([ruleAction.parameters[@"set_tweak"] isEqualToString:@"highlight"])
                {
                    // Check the highlight tweak "value"
                    // If not present, highlight. Else check its value before highlighting
                    if (nil == ruleAction.parameters[@"value"] || YES == [ruleAction.parameters[@"value"] boolValue])
                    {
                        highlight = [NSString stringWithFormat:@", %@", [VectorL10n notificationSettingsHighlight]];
                    }
                }
            }
        }
        
        if (notify.length)
        {
            _ruleActions.text = [NSString stringWithFormat:@"%@%@%@", notify, sound, highlight];
        }
        
        if (_ruleActions.isHidden)
        {
            _ruleActions.hidden = NO;
            // Adjust layout by updating constraint
            _ruleDescriptionBottomConstraint.constant += _ruleActionsHeightConstraint.constant;
        }
    }
    
    _mxPushRule = mxPushRule;
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == _controlButton)
    {
        // Swap enable state
        [_mxSession.notificationCenter enableRule:_mxPushRule isEnabled:!_mxPushRule.enabled completion:nil];
    }
    else if (sender == _deleteButton)
    {
        [_mxSession.notificationCenter removeRule:_mxPushRule];
    }
}

@end
