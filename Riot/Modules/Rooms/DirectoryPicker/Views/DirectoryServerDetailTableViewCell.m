/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "DirectoryServerDetailTableViewCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation DirectoryServerDetailTableViewCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];

    self.detailDescLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
}

- (void)render:(id<MXKDirectoryServerCellDataStoring>)cellData
{
    [super render:cellData];

    if (cellData.includeAllNetworks)
    {

        self.detailDescLabel.text = [VectorL10n directoryServerAllRooms:cellData.homeserver];
    }
    else
    {
        self.detailDescLabel.text = [VectorL10n directoryServerAllNativeRooms];
    }
}

@end
