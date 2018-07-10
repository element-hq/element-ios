/*
 Copyright 2017 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "GroupsDataSource.h"

@implementation GroupsDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* sectionTitle = nil;
    
    // Check whether there are more than 1 section.
    if (self.groupInvitesSection != -1)
    {
        if (section == self.groupInvitesSection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"group_invite_section", @"Vector", nil);
        }
        else if (section == self.joinedGroupsSection)
        {
            sectionTitle = NSLocalizedStringFromTable(@"group_section", @"Vector", nil);
        }
    }
    
    return sectionTitle;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Enable edition only for the joined groups.
    return (indexPath.section == self.joinedGroupsSection);
}

@end
