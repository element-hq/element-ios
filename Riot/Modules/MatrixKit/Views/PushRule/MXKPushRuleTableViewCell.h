/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>

#import "MXKTableViewCell.h"

/**
 MKPushRuleTableViewCell instance is a table view cell used to display a notification rule.
 */
@interface MXKPushRuleTableViewCell : MXKTableViewCell

/**
 The displayed rule
 */
@property (nonatomic) MXPushRule* mxPushRule;

/**
 The related matrix session
 */
@property (nonatomic) MXSession* mxSession;

/**
 The graphics items
 */
@property (strong, nonatomic) IBOutlet UIButton* controlButton;

@property (strong, nonatomic) IBOutlet UIButton* deleteButton;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *deleteButtonWidthConstraint;

@property (strong, nonatomic) IBOutlet UILabel* ruleDescription;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ruleDescriptionBottomConstraint;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *ruleDescriptionLeftConstraint;


@property (strong, nonatomic) IBOutlet UILabel* ruleActions;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ruleActionsHeightConstraint;

/**
 Action registered on `UIControlEventTouchUpInside` event for both buttons.
 */
- (IBAction)onButtonPressed:(id)sender;

@end
