/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <MatrixSDK/MatrixSDK.h>

#import "MXKDirectoryServerCellDataStoring.h"

/**
 `MXKRoomMemberCellData` modelised the data for a `MXKRoomMemberTableViewCell` cell.
 */
@interface MXKDirectoryServerCellData : MXKCellData <MXKDirectoryServerCellDataStoring>

@end
