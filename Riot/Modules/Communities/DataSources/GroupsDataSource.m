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
#import "GeneratedInterface-Swift.h"

@interface GroupsDataSource() <BetaAnnounceCellDelegate>

@property (nonatomic) NSInteger betaAnnounceSection;
@property (nonatomic) BOOL showBetaAnnounce;

@end

@implementation GroupsDataSource

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithMatrixSession:matrixSession];
    if (self)
    {
    // TODO: Hide the banner for the moment. Wait for iterations on it.
//        _showBetaAnnounce = !RiotSettings.shared.hideSpaceBetaAnnounce;
        _showBetaAnnounce = NO;
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    self.betaAnnounceSection = self.groupInvitesSection = self.joinedGroupsSection = -1;
    
    // Check whether all data sources are ready before rendering groups.
    if (self.state == MXKDataSourceStateReady)
    {
        if (self.showBetaAnnounce)
        {
            self.betaAnnounceSection = count++;
        }
        if (groupsInviteCellDataArray.count)
        {
            self.groupInvitesSection = count++;
        }
        if (groupsCellDataArray.count)
        {
            self.joinedGroupsSection = count++;
        }
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == self.betaAnnounceSection)
    {
        BetaAnnounceCell *cell = [tableView dequeueReusableCellWithIdentifier:BetaAnnounceCell.reuseIdentifier forIndexPath:indexPath];
        [cell vc_hideSeparator];
        [cell updateWithTheme:ThemeService.shared.theme];
        cell.delegate = self;
        return cell;
        
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == self.betaAnnounceSection)
    {
        return 1;
    }
    
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* sectionTitle = nil;
    
    // Check whether there are more than 1 section.
    if (self.groupInvitesSection != -1)
    {
        if (section == self.groupInvitesSection)
        {
            sectionTitle = [VectorL10n groupInviteSection];
        }
        else if (section == self.joinedGroupsSection)
        {
            sectionTitle = [VectorL10n groupSection];
        }
    }
    
    return sectionTitle;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Enable edition only for the joined groups.
    return (indexPath.section == self.joinedGroupsSection);
}

#pragma mark - BetaAnnounceCellDelegate

- (void)betaAnnounceCellDidTapCloseButton:(BetaAnnounceCell *)cell
{
    self.showBetaAnnounce = NO;
    RiotSettings.shared.hideSpaceBetaAnnounce = YES;
    [self.delegate dataSource:self didCellChange:nil];
}

@end
