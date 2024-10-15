/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "DirectoryRecentTableViewCell.h"

#import "PublicRoomsDirectoryDataSource.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation DirectoryRecentTableViewCell

#pragma mark - Class methods

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.titleLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.descriptionLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
}

- (void)render:(PublicRoomsDirectoryDataSource *)publicRoomsDirectoryDataSource
{
    self.userInteractionEnabled = NO;
    self.chevronImageView.hidden = YES;

    // Show information according to the data source state
    switch (publicRoomsDirectoryDataSource.state)
    {
        case MXKDataSourceStatePreparing:
            self.titleLabel.text = [VectorL10n directorySearchingTitle];
            self.descriptionLabel.text = @"";
            break;

        case MXKDataSourceStateReady:
        {
            if (publicRoomsDirectoryDataSource.searchPattern)
            {
                self.titleLabel.text = [VectorL10n directorySearchResultsTitle];

                // Do we need to display like ">20 results found" or "18 results found"?
                if (publicRoomsDirectoryDataSource.searchResultsCountIsLimited && publicRoomsDirectoryDataSource.searchResultsCount > 0)
                {
                    self.descriptionLabel.text = [VectorL10n directorySearchResultsMoreThan:publicRoomsDirectoryDataSource.searchResultsCount :publicRoomsDirectoryDataSource.searchPattern];
                }
                else
                {
                    self.descriptionLabel.text = [VectorL10n directorySearchResults:publicRoomsDirectoryDataSource.searchResultsCount :publicRoomsDirectoryDataSource.searchPattern];
                }
            }
            else
            {
                self.titleLabel.text = [VectorL10n directoryCellTitle];
                self.descriptionLabel.text = [VectorL10n directoryCellDescription:publicRoomsDirectoryDataSource.searchResultsCount];
            }

            if (publicRoomsDirectoryDataSource.searchResultsCount)
            {
                self.userInteractionEnabled = YES;
                self.chevronImageView.hidden = NO;
            }
            break;
        }

        case MXKDataSourceStateFailed:
            self.titleLabel.text = [VectorL10n directorySearchingTitle];
            self.descriptionLabel.text = [VectorL10n directorySearchFail];
            break;

        default:
            break;
    }
}

+ (CGFloat)cellHeight
{
    return 74;
}

@end
