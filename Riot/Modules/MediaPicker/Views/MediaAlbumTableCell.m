/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MediaAlbumTableCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation MediaAlbumTableCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.albumDisplayNameLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.albumCountLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
}

@end
