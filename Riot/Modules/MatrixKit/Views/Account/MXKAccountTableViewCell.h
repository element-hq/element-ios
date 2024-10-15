/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

#import "MXKImageView.h"
#import "MXKAccount.h"

/**
 MXKAccountTableViewCell instance is a table view cell used to display a matrix user.
 */
@interface MXKAccountTableViewCell : MXKTableViewCell

/**
 The displayed account
 */
@property (nonatomic) MXKAccount* mxAccount;

/**
 The default account picture displayed when no picture is defined.
 */
@property (nonatomic) UIImage *picturePlaceholder;

@property (strong, nonatomic) IBOutlet MXKImageView* accountPicture;

@property (strong, nonatomic) IBOutlet UILabel* accountDisplayName;

@property (strong, nonatomic) IBOutlet UISwitch* accountSwitchToggle;

@end
