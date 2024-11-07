/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

#import "MXKCellRendering.h"

#import "MXKRecentCellDataStoring.h"

/**
 `MXKRecentTableViewCell` instances display a room in the context of the recents list.
 */
@interface MXKRecentTableViewCell : MXKTableViewCell <MXKCellRendering>
{
@protected
    /**
     The current cell data displayed by the table view cell
     */
    id<MXKRecentCellDataStoring> roomCellData;
}

@property (weak, nonatomic) IBOutlet UILabel *roomTitle;
@property (weak, nonatomic) IBOutlet UILabel *lastEventDescription;
@property (weak, nonatomic) IBOutlet UILabel *lastEventDate;

@end
