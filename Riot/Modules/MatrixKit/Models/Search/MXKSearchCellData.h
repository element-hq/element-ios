/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKCellData.h"
#import "MXKSearchCellDataStoring.h"

/**
 `MXKSearchCellData` modelised the data for a `MXKSearchCell` cell.
 */
@interface MXKSearchCellData : MXKCellData <MXKSearchCellDataStoring>

@end
