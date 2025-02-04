// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import <UIKit/UIKit.h>

#import "RoomTimelineCellIdentifier.h"
#import "MXKCellRendering.h"

NS_ASSUME_NONNULL_BEGIN

/// Enables to register and provide room timeline cells
@protocol RoomTimelineCellProvider <NSObject>

/// Register timeline cells for the given table view
- (void)registerCellsForTableView:(UITableView*)tableView;

/// Get timeline cell class from cell identifier
- (Class<MXKCellRendering>)cellViewClassForCellIdentifier:(RoomTimelineCellIdentifier)identifier;

@end

NS_ASSUME_NONNULL_END

