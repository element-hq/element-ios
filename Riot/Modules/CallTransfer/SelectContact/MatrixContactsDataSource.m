// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import "MatrixContactsDataSource.h"

#import "GeneratedInterface-Swift.h"

@implementation MatrixContactsDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        hideNonMatrixEnabledContacts = YES;
    }
    return self;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == filteredLocalContactsSection)
    {
        return [VectorL10n contactsAddressBookSection];
    }
    else
    {
        return [VectorL10n callTransferContactsAll];
    }
}

@end
