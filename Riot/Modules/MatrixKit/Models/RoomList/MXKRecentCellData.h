/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import "MXKRecentCellDataStoring.h"

/**
 `MXKRecentCellData` modelised the data for a `MXKRecentTableViewCell` cell.
 */
@interface MXKRecentCellData : MXKCellData <MXKRecentCellDataStoring>

@end
