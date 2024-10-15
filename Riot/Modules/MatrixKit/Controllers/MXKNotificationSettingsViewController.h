/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>

#import "MXKTableViewController.h"
#import "MXKAccount.h"

/**
 'MXKNotificationSettingsViewController' instance may be used to display the notification settings (account's push rules).
 Presently only the Global notification settings are supported.
 */
@interface MXKNotificationSettingsViewController : MXKTableViewController

/**
 The account who owns the displayed notification settings.
 */
@property (nonatomic) MXKAccount *mxAccount;

@end

