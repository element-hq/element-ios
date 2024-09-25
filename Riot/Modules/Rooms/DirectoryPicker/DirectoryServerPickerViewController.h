/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import "MatrixKit.h"

@interface DirectoryServerPickerViewController : MXKTableViewController <MXKDataSourceDelegate, UITableViewDelegate>

/**
 Display data managed by the passed `MXKDirectoryServersDataSource`.

 @param dataSource the data source serving the data.
 @param onComplete a block called when the picker disappears. It provides data about
                   the selected protocol instance or homeserver.
                   Both nil means the user cancelled the picker.
 */
- (void)displayWithDataSource:(MXKDirectoryServersDataSource*)dataSource
                   onComplete:(void (^)(id<MXKDirectoryServerCellDataStoring> cellData))onComplete;

@end

