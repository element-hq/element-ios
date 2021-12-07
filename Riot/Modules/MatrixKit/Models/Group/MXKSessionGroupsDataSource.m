/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 Copyright 2019 The Matrix.org Foundation C.I.C

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

#import "MXKSessionGroupsDataSource.h"

#import "NSBundle+MatrixKit.h"

#import "MXKConstants.h"

#import "MXKSwiftHeader.h"

#pragma mark - Constant definitions
NSString *const kMXKGroupCellIdentifier = @"kMXKGroupCellIdentifier";


@interface MXKSessionGroupsDataSource ()
{
    /**
     Internal array used to regulate change notifications.
     Cell data changes are stored instantly in this array.
     We wait at least for 500 ms between two notifications of the delegate.
     */
    NSMutableArray *internalCellDataArray;
    
    /*
     Timer to not notify the delegate on every changes.
     */
    NSTimer *timer;
    
    /*
     Tells whether some changes must be notified.
     */
    BOOL isDataChangePending;
    
    /**
     Store the current search patterns list.
     */
    NSArray* searchPatternsList;
}

@end

@implementation MXKSessionGroupsDataSource

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithMatrixSession:matrixSession];
    if (self)
    {
        internalCellDataArray = [NSMutableArray array];
        groupsCellDataArray = [NSMutableArray array];
        groupsInviteCellDataArray = [NSMutableArray array];
        
        isDataChangePending = NO;
        
        // Set default data and view classes
        [self registerCellDataClass:MXKGroupCellData.class forCellIdentifier:kMXKGroupCellIdentifier];
    }
    return self;
}

- (void)destroy
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    groupsCellDataArray = nil;
    groupsInviteCellDataArray = nil;
    internalCellDataArray = nil;
    
    searchPatternsList = nil;
    
    [timer invalidate];
    timer = nil;
    
    [super destroy];
}

- (void)didMXSessionStateChange
{
    if (MXSessionStateRunning <= self.mxSession.state)
    {
        // Check whether some data have been already load
        if (0 == internalCellDataArray.count)
        {
            [self loadData];
        }
        else if (self.mxSession.state == MXSessionStateRunning)
        {
            // Refresh the group data
            [self refreshGroupsSummary:nil];
        }
    }
}

#pragma mark -

- (void)refreshGroupsSummary:(void (^)(void))completion
{
    MXLogDebug(@"[MXKSessionGroupsDataSource] refreshGroupsSummary");
    
    __block NSUInteger count = internalCellDataArray.count;
    
    if (count)
    {
        for (id<MXKGroupCellDataStoring> groupData in internalCellDataArray)
        {
            // Force the matrix session to refresh the group summary.
            [self.mxSession updateGroupSummary:groupData.group success:^{
                
                if (completion && !(--count))
                {
                    // All the requests have been done.
                    completion ();
                }
                
            } failure:^(NSError *error) {
                
                MXLogDebug(@"[MXKSessionGroupsDataSource] refreshGroupsSummary: group summary update failed %@", groupData.group.groupId);
                
                if (completion && !(--count))
                {
                    // All the requests have been done.
                    completion ();
                }
                
            }];
        }
    }
    else if (completion)
    {
        completion();
    }
}

- (void)searchWithPatterns:(NSArray*)patternsList
{
    if (patternsList.count)
    {
        searchPatternsList = patternsList;
    }
    else
    {
        searchPatternsList = nil;
    }
    
    [self onCellDataChange];
}

- (id<MXKGroupCellDataStoring>)cellDataAtIndex:(NSIndexPath*)indexPath
{
    id<MXKGroupCellDataStoring> groupData;
    
    if (indexPath.section == _groupInvitesSection)
    {
        if (indexPath.row < groupsInviteCellDataArray.count)
        {
            groupData = groupsInviteCellDataArray[indexPath.row];
        }
    }
    else if (indexPath.section == _joinedGroupsSection)
    {
        if (indexPath.row < groupsCellDataArray.count)
        {
            groupData = groupsCellDataArray[indexPath.row];
        }
    }
    
    return groupData;
}

- (NSIndexPath*)cellIndexPathWithGroupId:(NSString*)groupId
{
    // Look for the cell
    if (_groupInvitesSection != -1)
    {
        for (NSInteger index = 0; index < groupsInviteCellDataArray.count; index ++)
        {
            id<MXKGroupCellDataStoring> groupData = groupsInviteCellDataArray[index];
            if ([groupId isEqualToString:groupData.group.groupId])
            {
                // Got it
                return [NSIndexPath indexPathForRow:index inSection:_groupInvitesSection];
            }
        }
    }
    
    if (_joinedGroupsSection != -1)
    {
        for (NSInteger index = 0; index < groupsCellDataArray.count; index ++)
        {
            id<MXKGroupCellDataStoring> groupData = groupsCellDataArray[index];
            if ([groupId isEqualToString:groupData.group.groupId])
            {
                // Got it
                return [NSIndexPath indexPathForRow:index inSection:_joinedGroupsSection];
            }
        }
    }
    
    return nil;
}

#pragma mark - Groups processing

- (void)loadData
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionNewGroupInviteNotification object:self.mxSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidJoinGroupNotification object:self.mxSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidLeaveGroupNotification object:self.mxSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidUpdateGroupSummaryNotification object:self.mxSession];
    
    // Reset the table
    [internalCellDataArray removeAllObjects];
    
    // Retrieve the MXKCellData class to manage the data
    Class class = [self cellDataClassForCellIdentifier:kMXKGroupCellIdentifier];
    NSAssert([class conformsToProtocol:@protocol(MXKGroupCellDataStoring)], @"MXKSessionGroupsDataSource only manages MXKCellData that conforms to MXKGroupCellDataStoring protocol");
    
    // Listen to MXSession groups changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNewGroupInvite:) name:kMXSessionNewGroupInviteNotification object:self.mxSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didJoinGroup:) name:kMXSessionDidJoinGroupNotification object:self.mxSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLeaveGroup:) name:kMXSessionDidLeaveGroupNotification object:self.mxSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroup:) name:kMXSessionDidUpdateGroupSummaryNotification object:self.mxSession];
    
    NSDate *startDate = [NSDate date];
    
    NSArray *groups = self.mxSession.groups;
    for (MXGroup *group in groups)
    {
        id<MXKGroupCellDataStoring> cellData = [[class alloc] initWithGroup:group andGroupsDataSource:self];
        if (cellData)
        {
            [internalCellDataArray addObject:cellData];
            
            // Force the matrix session to refresh the group summary.
            [self.mxSession updateGroupSummary:group success:nil failure:^(NSError *error) {
                MXLogDebug(@"[MXKSessionGroupsDataSource] loadData: group summary update failed %@", group.groupId);
            }];
        }
    }
    
    MXLogDebug(@"[MXKSessionGroupsDataSource] Loaded %tu groups in %.3fms", groups.count, [[NSDate date] timeIntervalSinceDate:startDate] * 1000);
    
    [self sortCellData];
    [self onCellDataChange];
}

- (void)didUpdateGroup:(NSNotification *)notif
{
    MXGroup *group = notif.userInfo[kMXSessionNotificationGroupKey];
    if (group)
    {
        id<MXKGroupCellDataStoring> groupData = [self cellDataWithGroupId:group.groupId];
        if (groupData)
        {
            [groupData updateWithGroup:group];
        }
        else
        {
            MXLogDebug(@"[MXKSessionGroupsDataSource] didUpdateGroup: Cannot find the changed group for %@ (%@). It is probably not managed by this group data source", group.groupId, group);
            return;
        }
    }
    
    [self sortCellData];
    [self onCellDataChange];
}

- (void)onNewGroupInvite:(NSNotification *)notif
{
    MXGroup *group = notif.userInfo[kMXSessionNotificationGroupKey];
    if (group)
    {
        // Add the group if there is not yet a cell for it
        id<MXKGroupCellDataStoring> groupData = [self cellDataWithGroupId:group.groupId];
        if (nil == groupData)
        {
            MXLogDebug(@"MXKSessionGroupsDataSource] Add new group invite: %@", group.groupId);
            
            // Retrieve the MXKCellData class to manage the data
            Class class = [self cellDataClassForCellIdentifier:kMXKGroupCellIdentifier];
            
            id<MXKGroupCellDataStoring> cellData = [[class alloc] initWithGroup:group andGroupsDataSource:self];
            if (cellData)
            {
                [internalCellDataArray addObject:cellData];
                
                [self sortCellData];
                [self onCellDataChange];
            }
        }
    }
}

- (void)didJoinGroup:(NSNotification *)notif
{
    MXGroup *group = notif.userInfo[kMXSessionNotificationGroupKey];
    if (group)
    { 
        id<MXKGroupCellDataStoring> groupData = [self cellDataWithGroupId:group.groupId];
        if (groupData)
        {
            MXLogDebug(@"MXKSessionGroupsDataSource] Update joined room: %@", group.groupId);
            [groupData updateWithGroup:group];
        }
        else
        {
            MXLogDebug(@"MXKSessionGroupsDataSource] Add new joined invite: %@", group.groupId);
            
            // Retrieve the MXKCellData class to manage the data
            Class class = [self cellDataClassForCellIdentifier:kMXKGroupCellIdentifier];
            
            id<MXKGroupCellDataStoring> cellData = [[class alloc] initWithGroup:group andGroupsDataSource:self];
            if (cellData)
            {
                [internalCellDataArray addObject:cellData];
            }
        }
        
        [self sortCellData];
        [self onCellDataChange];
    }
}

- (void)didLeaveGroup:(NSNotification *)notif
{
    NSString *groupId = notif.userInfo[kMXSessionNotificationGroupIdKey];
    if (groupId)
    {
        [self removeGroup:groupId];
    }
}

- (void)removeGroup:(NSString*)groupId
{
    id<MXKGroupCellDataStoring> groupData = [self cellDataWithGroupId:groupId];
    if (groupData)
    {
        MXLogDebug(@"MXKSessionGroupsDataSource] Remove left group: %@", groupId);
        
        [internalCellDataArray removeObject:groupData];
        
        [self sortCellData];
        [self onCellDataChange];
    }
}

- (void)onCellDataChange
{
    isDataChangePending = NO;
    
    // Check no notification was done recently.
    // Note: do not wait in case of search
    if (timer == nil || searchPatternsList)
    {
        [timer invalidate];
        timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkPendingUpdate:) userInfo:nil repeats:NO];
        
        // Prepare cell data array, and notify the delegate.
        [self prepareCellDataAndNotifyChanges];
    }
    else
    {
        isDataChangePending = YES;
    }
}

- (IBAction)checkPendingUpdate:(id)sender
{
    [timer invalidate];
    timer = nil;
    
    if (isDataChangePending)
    {
        [self onCellDataChange];
    }
}

- (void)sortCellData
{
    // Order alphabetically the groups
    [internalCellDataArray sortUsingComparator:^NSComparisonResult(id<MXKGroupCellDataStoring> cellData1, id<MXKGroupCellDataStoring> cellData2)
     {
         if (cellData1.sortingDisplayname.length && cellData2.sortingDisplayname.length)
         {
             return [cellData1.sortingDisplayname compare:cellData2.sortingDisplayname options:NSCaseInsensitiveSearch];
         }
         else if (cellData1.sortingDisplayname.length)
         {
             return NSOrderedAscending;
         }
         else if (cellData2.sortingDisplayname.length)
         {
             return NSOrderedDescending;
         }
         return NSOrderedSame;
     }];
}

- (void)prepareCellDataAndNotifyChanges
{
    // Prepare the cell data arrays by considering the potential filter.
    [groupsInviteCellDataArray removeAllObjects];
    [groupsCellDataArray removeAllObjects];
    for (id<MXKGroupCellDataStoring> groupData in internalCellDataArray)
    {
        BOOL isKept = !searchPatternsList;
        
        for (NSString* pattern in searchPatternsList)
        {
            if (groupData.groupDisplayname && [groupData.groupDisplayname rangeOfString:pattern options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                isKept = YES;
                break;
            }
        }
        
        if (isKept)
        {
            if (groupData.group.membership == MXMembershipInvite)
            {
                [groupsInviteCellDataArray addObject:groupData];
            }
            else
            {
                [groupsCellDataArray addObject:groupData];
            }
        }
    }
    
    // Update here data source state
    if (state != MXKDataSourceStateReady)
    {
        state = MXKDataSourceStateReady;
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:didStateChange:)])
        {
            [self.delegate dataSource:self didStateChange:state];
        }
    }
    
    // And inform the delegate about the update
    [self.delegate dataSource:self didCellChange:nil];
}

// Find the cell data that stores information about the given group id
- (id<MXKGroupCellDataStoring>)cellDataWithGroupId:(NSString*)groupId
{
    id<MXKGroupCellDataStoring> theGroupData;
    for (id<MXKGroupCellDataStoring> groupData in internalCellDataArray)
    {
        if ([groupData.group.groupId isEqualToString:groupId])
        {
            theGroupData = groupData;
            break;
        }
    }
    return theGroupData;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    _groupInvitesSection = _joinedGroupsSection = -1;
    
    // Check whether all data sources are ready before rendering groups.
    if (self.state == MXKDataSourceStateReady)
    {
        if (groupsInviteCellDataArray.count)
        {
            _groupInvitesSection = count++;
        }
        if (groupsCellDataArray.count)
        {
            _joinedGroupsSection = count++;
        }
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _groupInvitesSection)
    {
        return groupsInviteCellDataArray.count;
    }
    else if (section == _joinedGroupsSection)
    {
        return groupsCellDataArray.count;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* sectionTitle = nil;
    
    if (section == _groupInvitesSection)
    {
        sectionTitle = [MatrixKitL10n groupInviteSection];
    }
    else if (section == _joinedGroupsSection)
    {
        sectionTitle = [MatrixKitL10n groupSection];
    }
    
    return sectionTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKGroupCellDataStoring> groupData;
    
    if (indexPath.section == _groupInvitesSection)
    {
        if (indexPath.row < groupsInviteCellDataArray.count)
        {
            groupData = groupsInviteCellDataArray[indexPath.row];
        }
    }
    else if (indexPath.section == _joinedGroupsSection)
    {
        if (indexPath.row < groupsCellDataArray.count)
        {
            groupData = groupsCellDataArray[indexPath.row];
        }
    }
    
    if (groupData)
    {
        NSString *cellIdentifier = [self.delegate cellReuseIdentifierForCellData:groupData];
        if (cellIdentifier)
        {
            UITableViewCell<MXKCellRendering> *cell  = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            
            // Make sure we listen to user actions on the cell
            cell.delegate = self;
            
            // Make the bubble display the data
            [cell render:groupData];
            
            return cell;
        }
    }
    
    // Return a fake cell to prevent app from crashing.
    return [[UITableViewCell alloc] init];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self leaveGroupAtIndexPath:indexPath];
    }
}

- (void)leaveGroupAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKGroupCellDataStoring> cellData = [self cellDataAtIndex:indexPath];
    
    if (cellData.group)
    {
        __weak typeof(self) weakSelf = self;
        
        [self.mxSession leaveGroup:cellData.group.groupId success:^{
            
            if (weakSelf)
            {
                // Refresh the table content
                typeof(self) self = weakSelf;
                [self removeGroup:cellData.group.groupId];
            }
            
        } failure:^(NSError *error) {
            
            MXLogDebug(@"[MXKSessionGroupsDataSource] Failed to leave group (%@)", cellData.group.groupId);
            
            // Notify MatrixKit user
            NSString *myUserId = self.mxSession.myUser.userId;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
            
        }];
    }
}


@end
