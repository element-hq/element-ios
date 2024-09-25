/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 `FilesSearchCellData` prepares the data for the Vector cell used to display the files search result.
 */
@interface FilesSearchCellData : MXKCellData <MXKSearchCellDataStoring>
{
    /**
     The data source owner of this instance.
     */
    MXKSearchDataSource *searchDataSource;
}

@end
