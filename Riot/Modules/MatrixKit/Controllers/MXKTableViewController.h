/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKViewControllerHandling.h"

/**
 MXKViewController extends UITableViewController to handle requirements for
 any matrixKit table view controllers (see MXKViewControllerHandling protocol).
 */

@interface MXKTableViewController : UITableViewController <MXKViewControllerHandling>

@end

