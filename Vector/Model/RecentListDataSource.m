/*
 Copyright 2015 OpenMarket Ltd

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

#import "RecentListDataSource.h"

#import "AppDelegate.h"

#import "EventFormatter.h"

#import "NSBundle+MatrixKit.h"

@interface RecentListDataSource ()
{
    //
    UIButton *recentsShrinkButton;
    BOOL areRecentsShrinked;
    
    // Homeserver list
    NSMutableArray *homeServers;
    // All registered REST clients
    NSMutableArray *restClients;
    // REST clients by homeserver
    NSMutableDictionary *restClientDict;
    // Public rooms by homeserver
    NSMutableDictionary *publicRoomsDict;
    // Array of shrinked homeservers.
    NSMutableArray *shrinkedHomeServers;
    // Count current refresh requests
    NSInteger refreshCount;
    
    // List of public room names to highlight in displayed list
    NSArray* highlightedPublicRooms;
    
    // Search in public rooms
    NSMutableDictionary  *filteredPublicRoomsDict;
}
@end

@implementation RecentListDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.eventFormatter = [[EventFormatter alloc] initWithMatrixSession:self.mxSession];
        self.eventFormatter.isForSubtitle = YES;
        
        highlightedPublicRooms = @[@"#matrix:matrix.org", @"#matrix-dev:matrix.org", @"#matrix-fr:matrix.org"]; // Add here a room name to highlight its display in public room list
    }
    return self;
}

- (void)destroy
{
    homeServers = nil;
    restClients = nil;
    restClientDict = nil;
    publicRoomsDict = nil;
    filteredPublicRoomsDict = nil;
    shrinkedHomeServers = nil;
    
    highlightedPublicRooms = nil;
    
    [super destroy];
}

#pragma mark -

- (void)addRestClient:(MXRestClient*)restClient onComplete:(void (^)())onComplete
{
    if (!restClient.homeserver)
    {
        return;
    }
    
    if (!homeServers)
    {
        homeServers = [NSMutableArray array];
    }
    if (!restClients)
    {
        restClients = [NSMutableArray array];
    }
    if (!restClientDict)
    {
        restClientDict = [NSMutableDictionary dictionary];
    }
    
    if ([restClients indexOfObject:restClient] == NSNotFound)
    {
        [restClients addObject:restClient];
        
        if ([homeServers indexOfObject:restClient.homeserver] == NSNotFound){
            [homeServers addObject:restClient.homeserver];
            [restClientDict setObject:restClient forKey:restClient.homeserver];
            [self refreshPublicRooms:restClient onComplete:onComplete];
        }
    }
}

- (void)removeRestClient:(MXRestClient *)restClient
{
    NSUInteger index = [restClients indexOfObject:restClient];
    if (index != NSNotFound)
    {
        [restClients removeObjectAtIndex:index];
        
        // Check whether this client was reported in rest client dictionary
        for (NSString *homeserver in homeServers)
        {
            if ([restClientDict objectForKey:homeserver] == restClient)
            {
                [restClientDict removeObjectForKey:homeserver];
                BOOL removeHomeServer = YES;
                
                // Look for an other rest client for this homeserver (if any)
                for (MXRestClient *client in restClients)
                {
                    if ([client.homeserver isEqualToString:homeserver])
                    {
                        [restClientDict setObject:client forKey:homeserver];
                        removeHomeServer = NO;
                        break;
                    }
                }
                
                if (removeHomeServer)
                {
                    [homeServers removeObject:homeserver];
                    [publicRoomsDict removeObjectForKey:homeserver];
                }
                
                [self refreshPublicRooms:nil onComplete:nil];
                break;
            }
        }
    }
}

- (void)removeClosedRestClients
{
    // We check here all registered clients (Some of them may have been closed).
    for (NSInteger index = 0; index < restClients.count; index ++)
    {
        MXRestClient *restClient = [restClients objectAtIndex:index];
        if (!restClient.homeserver.length)
        {
            [self removeRestClient:restClient];
        }
    }
}

- (void)refreshPublicRooms:(MXRestClient*)restClient onComplete:(void (^)())onComplete
{
    NSArray *selectedClients;
    if (restClient)
    {
        selectedClients = @[restClient];
    }
    else
    {
        // refresh registered clients by removing closed ones.
        [self removeClosedRestClients];
        
        // Consider only one client by homeserver.
        selectedClients = restClientDict.allValues;
    }
    
    if (!selectedClients.count)
    {
        return;
    }
    
    refreshCount += selectedClients.count;
    
    if (!publicRoomsDict)
    {
        publicRoomsDict = [NSMutableDictionary dictionaryWithCapacity:restClientDict.count];
    }
    if (!shrinkedHomeServers)
    {
        shrinkedHomeServers = [NSMutableArray array];
    }
    
    for (NSInteger index = 0; index < selectedClients.count; index ++)
    {
        MXRestClient *restClient = [selectedClients objectAtIndex:index];
        
        // Retrieve public rooms
        [restClient publicRooms:^(NSArray *rooms) {
            
            NSArray *publicRooms = [rooms sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                
                MXPublicRoom *firstRoom =  (MXPublicRoom*)a;
                MXPublicRoom *secondRoom = (MXPublicRoom*)b;
                
                // Compare member count
                if (firstRoom.numJoinedMembers < secondRoom.numJoinedMembers)
                {
                    return NSOrderedDescending;
                }
                else if (firstRoom.numJoinedMembers > secondRoom.numJoinedMembers)
                {
                    return NSOrderedAscending;
                }
                else
                {
                    // Alphabetic order
                    return [firstRoom.displayname compare:secondRoom.displayname options:NSCaseInsensitiveSearch];
                }
            }];
            
            if (publicRooms.count && restClient.homeserver)
            {
                [publicRoomsDict setObject:publicRooms forKey:restClient.homeserver];
            }
            
            refreshCount--;
            if (refreshCount == 0)
            {
                [self.delegate dataSource:self didCellChange:nil];
                
                if (onComplete)
                {
                    onComplete();
                }
            }
        } failure:^(NSError *error) {
            
            NSLog(@"[RecentListDataSource] Failed to get public rooms for %@: %@", restClient.homeserver, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
            
            refreshCount--;
            if (refreshCount == 0)
            {
                [self.delegate dataSource:self didCellChange:nil];
                 
                 if (onComplete)
                 {
                     onComplete();
                 }
            }
            
        }];
    }
}

- (MXPublicRoom*)publicRoomAtIndexPath:(NSIndexPath*)indexPath
{
    MXPublicRoom *publicRoom = nil;
    
    if (_publicRoomsFirstSection != -1 && indexPath.section >= _publicRoomsFirstSection)
    {
        NSInteger index = indexPath.section - _publicRoomsFirstSection;
        if (index < homeServers.count)
        {
            NSString *homeserver = [homeServers objectAtIndex:index];
            NSArray *publicRooms = nil;
            if (filteredPublicRoomsDict)
            {
                publicRooms = [filteredPublicRoomsDict objectForKey:homeserver];
            }
            else
            {
                publicRooms = [publicRoomsDict objectForKey:homeserver];
            }
            
            if (indexPath.row < publicRooms.count)
            {
                publicRoom = [publicRooms objectAtIndex:indexPath.row];
            }
        }
    }
    
    return publicRoom;
}

#pragma mark - Override MXKRecentsDataSource

- (void)addMatrixSession:(MXSession *)matrixSession
{
    [super addMatrixSession:matrixSession];
    
    [self addRestClient:matrixSession.matrixRestClient onComplete:nil];
}

- (void)removeMatrixSession:(MXSession*)matrixSession
{
    [super removeMatrixSession:matrixSession];
    
    // Remove the related REST Client
    if (matrixSession.matrixRestClient)
    {
        [self removeRestClient:matrixSession.matrixRestClient];
    }
    else
    {
        // Here the matrix session is closed, the rest client reference has been removed.
        // Force a full refresh
        [self refreshPublicRooms:nil onComplete:nil];
    }
}

- (void)searchWithPatterns:(NSArray*)patternsList
{
    [super searchWithPatterns:patternsList];
    
    // Update filtered list
    if (patternsList.count)
    {
        if (filteredPublicRoomsDict)
        {
            [filteredPublicRoomsDict removeAllObjects];
        }
        else
        {
            filteredPublicRoomsDict = [NSMutableDictionary dictionaryWithCapacity:homeServers.count];
        }
        
        for (NSString* pattern in patternsList)
        {
            for (NSString *homeserver in homeServers)
            {
                NSArray *publicRooms = [publicRoomsDict objectForKey:homeserver];
                
                NSMutableArray *filteredRooms = [filteredPublicRoomsDict objectForKey:homeserver];
                if (!filteredRooms)
                {
                    filteredRooms = [NSMutableArray array];
                }
                
                for (MXPublicRoom *publicRoom in publicRooms)
                {
                    if ([[publicRoom displayname] rangeOfString:pattern options:NSCaseInsensitiveSearch].location != NSNotFound)
                    {
                        if ([filteredRooms indexOfObject:publicRoom] == NSNotFound)
                        {
                            [filteredRooms addObject:publicRoom];
                        }
                    }
                }
                
                if (filteredRooms.count)
                {
                    [filteredPublicRoomsDict setObject:filteredRooms forKey:homeserver];
                }
            }
        }
    }
    else
    {
        filteredPublicRoomsDict = nil;
    }
    
    [self.delegate dataSource:self didCellChange:nil];
}

- (CGFloat)cellHeightAtIndexPath:(NSIndexPath*)indexPath
{
    if (_publicRoomsFirstSection != -1 && indexPath.section >= _publicRoomsFirstSection)
    {
        return 60;
    }
    return [super cellHeightAtIndexPath:indexPath];
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    UIView *sectionHeader = nil;
    NSString* sectionTitle;
    BOOL isShrinked = NO;
    NSInteger buttonTag = 0;
    
    if (section < _publicRoomsFirstSection)
    {
        sectionHeader = [super viewForHeaderInSection:section withFrame:frame];
        
        // Here sectionHeader is nil if there is only one session
        if (!sectionHeader)
        {
            // Let's create a header to shrink recents
            sectionTitle = self.mxSession.myUser.userId;
            if (self.unreadCount)
            {
                sectionTitle = [NSString stringWithFormat:@"%@ (%tu)", sectionTitle, self.unreadCount];
            }
            
            isShrinked = areRecentsShrinked;
            buttonTag = 0;
        }
    }
    else
    {
        NSArray *publicRooms = nil;
        NSString *homeserver;
        NSInteger index = section - _publicRoomsFirstSection;
        if (index < homeServers.count)
        {
            homeserver = [homeServers objectAtIndex:index];
            
            if (filteredPublicRoomsDict)
            {
                publicRooms = [filteredPublicRoomsDict objectForKey:homeserver];
            }
            else
            {
                publicRooms = [publicRoomsDict objectForKey:homeserver];
            }
        }
        
        if (publicRooms)
        {
            sectionTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"public_room_section_title", @"Vector", nil), homeserver];
            isShrinked = ([shrinkedHomeServers indexOfObject:homeserver] != NSNotFound);
            buttonTag = self.displayedRecentsDataSourcesCount + index;
        }
    }
    
    if (!sectionHeader && sectionTitle.length)
    {
        sectionHeader = [[UIView alloc] initWithFrame:frame];
        sectionHeader.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
        
        // Add shrink button
        UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect frame = sectionHeader.frame;
        frame.origin.x = frame.origin.y = 0;
        shrinkButton.frame = frame;
        shrinkButton.backgroundColor = [UIColor clearColor];
        [shrinkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        shrinkButton.tag = buttonTag;
        [sectionHeader addSubview:shrinkButton];
        sectionHeader.userInteractionEnabled = YES;
        
        // Add shrink icon
        UIImage *chevron;
        if (isShrinked)
        {
            chevron = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"disclosure"];
        }
        else
        {
            chevron = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"shrink"];
        }
        UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevron];
        chevronView.contentMode = UIViewContentModeCenter;
        frame = chevronView.frame;
        frame.origin.x = sectionHeader.frame.size.width - frame.size.width - 8;
        frame.origin.y = (sectionHeader.frame.size.height - frame.size.height) / 2;
        chevronView.frame = frame;
        [sectionHeader addSubview:chevronView];
        chevronView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
        
        // Add label
        frame = sectionHeader.frame;
        frame.origin.x = 5;
        frame.origin.y = 5;
        frame.size.width = chevronView.frame.origin.x - 10;
        frame.size.height -= 10;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.font = [UIFont boldSystemFontOfSize:16];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.text = sectionTitle;
        [sectionHeader addSubview:headerLabel];
    }
    
    return sectionHeader;
}

- (IBAction)onButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *shrinkButton = (UIButton*)sender;
        
        if (shrinkButton.tag < self.displayedRecentsDataSourcesCount)
        {
            if (self.displayedRecentsDataSourcesCount > 1)
            {
                [super onButtonPressed:sender];
            }
            else
            {
                areRecentsShrinked = !areRecentsShrinked;
                [self.delegate dataSource:self didCellChange:nil];
            }
        }
        else
        {
            NSInteger tag = shrinkButton.tag - self.displayedRecentsDataSourcesCount;
            if (tag < homeServers.count)
            {
                NSString *homeserver = [homeServers objectAtIndex:tag];
                
                NSUInteger index = [shrinkedHomeServers indexOfObject:homeserver];
                if (index != NSNotFound)
                {
                    // Disclose the public rooms list
                    [shrinkedHomeServers removeObjectAtIndex:index];
                }
                else
                {
                    // Shrink the public rooms list from this homeserver.
                    [shrinkedHomeServers addObject:homeserver];
                }
                // trigger table refresh
                [self.delegate dataSource:self didCellChange:nil];
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionNb = [super numberOfSectionsInTableView:tableView];
    
    _publicRoomsFirstSection = -1;
    
    if (homeServers.count)
    {
        // Add a section for each list of public rooms
        _publicRoomsFirstSection = sectionNb;
        sectionNb += homeServers.count;
    }
    
    return sectionNb;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (_publicRoomsFirstSection == -1 || section < _publicRoomsFirstSection)
    {
        count = [super tableView:tableView numberOfRowsInSection:section];
        
        if (areRecentsShrinked)
        {
            count = 0;
        }
        
    }
    else
    {
        NSArray *publicRooms = nil;
        NSInteger index = section - _publicRoomsFirstSection;
        if (index < homeServers.count)
        {
            NSString *homeserver = [homeServers objectAtIndex:index];
            
            // Check whether the list is shrinked
            if ([shrinkedHomeServers indexOfObject:homeserver] == NSNotFound)
            {
                if (filteredPublicRoomsDict)
                {
                    publicRooms = [filteredPublicRoomsDict objectForKey:homeserver];
                }
                else
                {
                    publicRooms = [publicRoomsDict objectForKey:homeserver];
                }
            }
        }
        
        count = publicRooms.count;
    }
    
    return count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Public rooms are not editable
    if (_publicRoomsFirstSection == -1 || indexPath.section < _publicRoomsFirstSection)
    {
        return YES;
    }
    
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (_publicRoomsFirstSection == -1 || indexPath.section < _publicRoomsFirstSection)
    {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else
    {
        MXKPublicRoomTableViewCell *publicRoomCell = [tableView dequeueReusableCellWithIdentifier:[MXKPublicRoomTableViewCell defaultReuseIdentifier]];
        if (!publicRoomCell)
        {
            publicRoomCell = [[MXKPublicRoomTableViewCell alloc] init];
        }
        
        MXPublicRoom *publicRoom = [self publicRoomAtIndexPath:indexPath];
        if (publicRoom)
        {
            [publicRoomCell render:publicRoom];
            // Highlight?
            publicRoomCell.highlightedPublicRoom = (publicRoomCell.roomDisplayName.text && [highlightedPublicRooms indexOfObject:publicRoomCell.roomDisplayName.text] != NSNotFound);
        }
        
        cell = publicRoomCell;
    }
    
    return cell;
}

@end
