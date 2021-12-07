// 
// Copyright 2020 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
