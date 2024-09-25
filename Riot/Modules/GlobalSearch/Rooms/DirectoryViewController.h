/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@class PublicRoomsDirectoryDataSource;

@interface DirectoryViewController : MXKTableViewController <UITableViewDelegate>

/**
 Display data managed by the passed `PublicRoomsDirectoryDataSource`.

 @param dataSource the data source serving the data.
 */
- (void)displayWitDataSource:(PublicRoomsDirectoryDataSource*)dataSource;

@end
