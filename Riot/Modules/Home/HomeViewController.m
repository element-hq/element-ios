/*
 Copyright 2015 OpenMarket Ltd
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

#import "HomeViewController.h"

#import "AppDelegate.h"

#import "RecentsDataSource.h"

#import "TableViewCellWithCollectionView.h"
#import "RoomCollectionViewCell.h"

#import "MXRoom+Riot.h"

@interface HomeViewController ()
{
    RecentsDataSource *recentsDataSource;
    
    // Room edition
    NSInteger selectedSection;
    NSString *selectedRoomId;
    UISwipeGestureRecognizer *horizontalSwipeGestureRecognizer;
    UISwipeGestureRecognizer *verticalSwipeGestureRecognizer;
    // The content offset of the collection in which the edited room is displayed.
    // We store this value to prevent the collection view from scrolling to the beginning (observed on iOS < 10).
    CGFloat selectedCollectionViewContentOffset;
}
@end

@implementation HomeViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    selectedSection = -1;
    selectedRoomId = nil;
    selectedCollectionViewContentOffset = -1;
    
    self.screenName = @"Home";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"HomeVCView";
    self.recentsTableView.accessibilityIdentifier = @"HomeVCTableView";
    
    // Tag the recents table with the its recents data source mode.
    // This will be used by the shared RecentsDataSource instance for sanity checks (see UITableViewDataSource methods).
    self.recentsTableView.tag = RecentsDataSourceModeHome;
    
    // Add the (+) button programmatically
    [self addPlusButton];
    
    // Register table view cell used for rooms collection.
    [self.recentsTableView registerClass:TableViewCellWithCollectionView.class forCellReuseIdentifier:TableViewCellWithCollectionView.defaultReuseIdentifier];
    
    // Change the table data source. It must be the home view controller itself.
    self.recentsTableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_home", @"Vector", nil);
    [AppDelegate theDelegate].masterTabBarController.navigationController.navigationBar.tintColor = kRiotColorGreen;
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = kRiotColorGreen;
    
    if (recentsDataSource)
    {
        // Take the lead on the shared data source.
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeHome];
    }

    [self moveAllCollectionsToLeft];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    if (selectedRoomId)
    {
        // Cancel room edition in case of device screen rotation.
        [self cancelEditionMode:YES];
    }
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];
}

- (void)moveAllCollectionsToLeft
{
    selectedCollectionViewContentOffset = -1;
    
    // Scroll all rooms collections to their beginning
    for (NSInteger section = 0; section < [self numberOfSectionsInTableView:self.recentsTableView]; section++)
    {
        UITableViewCell *firstSectionCell = [self.recentsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        if (firstSectionCell && [firstSectionCell isKindOfClass:TableViewCellWithCollectionView.class])
        {
            TableViewCellWithCollectionView *tableViewCell = (TableViewCellWithCollectionView*)firstSectionCell;

            if ([tableViewCell.collectionView numberOfItemsInSection:0] > 0)
            {
                [tableViewCell.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
            }
        }
    }
}

#pragma mark - Override RecentsViewController

- (void)displayList:(MXKRecentsDataSource *)listDataSource
{
    [super displayList:listDataSource];
    
    // Change the table data source. It must be the home view controller itself.
    self.recentsTableView.dataSource = self;
    
    // Keep a ref on the recents data source
    if ([listDataSource isKindOfClass:RecentsDataSource.class])
    {
        recentsDataSource = (RecentsDataSource*)listDataSource;
    }
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode != RecentsDataSourceModeHome)
    {
        return;
    }
    
    // TODO: refreshCurrentSelectedCell
    //[super refreshCurrentSelectedCell:forceVisible];
}

- (void)didTapOnSectionHeader:(UIGestureRecognizer*)gestureRecognizer
{
    UIView *view = gestureRecognizer.view;
    NSInteger section = view.tag;
    
    if (selectedRoomId)
    {
        [self cancelEditionMode:YES];
    }
    
    // Scroll to the top this section
    if ([self.recentsTableView numberOfRowsInSection:section] > 0)
    {
        [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    
    // Scroll to the beginning the corresponding rooms collection.
    UITableViewCell *firstSectionCell = [self.recentsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    if (firstSectionCell && [firstSectionCell isKindOfClass:TableViewCellWithCollectionView.class])
    {
        TableViewCellWithCollectionView *tableViewCell = (TableViewCellWithCollectionView*)firstSectionCell;
        
        if ([tableViewCell.collectionView numberOfItemsInSection:0] > 0)
        {
            [tableViewCell.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
        }
    }
}

- (void)scrollToTop:(BOOL)animated
{
    if (selectedRoomId)
    {
        [self cancelEditionMode:YES];
    }
    
    [super scrollToTop:animated];
}

- (void)onPlusButtonPressed
{
    if (selectedRoomId)
    {
        [self cancelEditionMode:YES];
    }
    
    [super onPlusButtonPressed];
}

- (void)cancelEditionMode:(BOOL)forceRefresh
{
    if (selectedRoomId)
    {
        // Ignore forceRefresh, a table refresh is forced at the end.
        [super cancelEditionMode:NO];
        
        editedRoomId = selectedRoomId = nil;
        
        if (selectedCollectionViewContentOffset == -1)
        {
            selectedSection = -1;
        }
        // Else, do not reset the selectedSection here,
        // it is used during the table refresh to apply the original collection view offset.
        
        // Remove existing gesture recognizers
        [self.recentsTableView removeGestureRecognizer:horizontalSwipeGestureRecognizer];
        horizontalSwipeGestureRecognizer = nil;
        [self.recentsTableView removeGestureRecognizer:verticalSwipeGestureRecognizer];
        verticalSwipeGestureRecognizer = nil;
        
        self.recentsTableView.scrollEnabled = YES;
        
        [self refreshRecentsTable];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the actual number of sections prepared in recents dataSource.
    return [recentsDataSource numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Edit the potential selected room (see `onCollectionViewCellLongPress`).
    editedRoomId = selectedRoomId;
    
    // Each rooms section is represented by only one collection view.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == recentsDataSource.conversationSection && !recentsDataSource.conversationCellDataArray.count)
        || (indexPath.section == recentsDataSource.peopleSection && !recentsDataSource.peopleCellDataArray.count))
    {
        return [recentsDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    TableViewCellWithCollectionView *tableViewCell = [tableView dequeueReusableCellWithIdentifier:TableViewCellWithCollectionView.defaultReuseIdentifier forIndexPath:indexPath];
    tableViewCell.collectionView.tag = indexPath.section;
    [tableViewCell.collectionView registerClass:RoomCollectionViewCell.class forCellWithReuseIdentifier:RoomCollectionViewCell.defaultReuseIdentifier];
    tableViewCell.collectionView.delegate = self;
    tableViewCell.collectionView.dataSource = self;
    tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (editedRoomId)
    {
        // Disable collection scrolling during edition
        tableViewCell.collectionView.scrollEnabled = NO;
        
        if (indexPath.section == selectedSection)
        {
            // Show edition menu
            tableViewCell.editionViewHeightConstraint.constant = 60;
            tableViewCell.editionViewBottomConstraint.constant = 5;
            tableViewCell.editionView.hidden = NO;
            
            MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
            
            // Update the edition menu content (Use the button tag to store the current value).
            tableViewCell.directChatButton.tag = room.isDirect;
            [tableViewCell.directChatButton addTarget:self action:@selector(onDirectChatButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            tableViewCell.directChatImageView.image = tableViewCell.directChatButton.tag ? [UIImage imageNamed:@"directChatOff"] : [UIImage imageNamed:@"directChatOn"];
            
            tableViewCell.notificationsButton.tag = room.isMute || room.isMentionsOnly;
            [tableViewCell.notificationsButton addTarget:self action:@selector(onNotificationsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            tableViewCell.notificationsImageView.image = tableViewCell.notificationsButton.tag ? [UIImage imageNamed:@"notifications"] : [UIImage imageNamed:@"notificationsOff"];
            
            // Get the room tag (use only the first one).
            MXRoomTag* currentTag = nil;
            if (room.accountData.tags)
            {
                NSArray<MXRoomTag*>* tags = room.accountData.tags.allValues;
                if (tags.count)
                {
                    currentTag = [tags objectAtIndex:0];
                }
            }
            
            tableViewCell.favouriteButton.tag = (currentTag && [kMXRoomTagFavourite isEqualToString:currentTag.name]);
            [tableViewCell.favouriteButton addTarget:self action:@selector(onFavouriteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            tableViewCell.favouriteImageView.image = tableViewCell.favouriteButton.tag ? [UIImage imageNamed:@"favouriteOff"] : [UIImage imageNamed:@"favourite"];
            
            tableViewCell.priorityButton.tag = (currentTag && [kMXRoomTagLowPriority isEqualToString:currentTag.name]);
            [tableViewCell.priorityButton addTarget:self action:@selector(onPriorityButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            tableViewCell.priorityImageView.image = tableViewCell.priorityButton.tag ? [UIImage imageNamed:@"priorityHigh"] : [UIImage imageNamed:@"priorityLow"];
            
            [tableViewCell.leaveButton addTarget:self action:@selector(onLeaveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            tableViewCell.leaveImageView.image = [UIImage imageNamed:@"leave"];
        }
    }
    
    return tableViewCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == recentsDataSource.conversationSection && !recentsDataSource.conversationCellDataArray.count)
        || (indexPath.section == recentsDataSource.peopleSection && !recentsDataSource.peopleCellDataArray.count))
    {
        return [recentsDataSource cellHeightAtIndexPath:indexPath];
    }
    
    // Retrieve the fixed height of the collection view cell used to display a room.
    CGFloat height = [RoomCollectionViewCell defaultCellSize].height + 1;
    
    // Check the conditions to display the edition menu
    if (editedRoomId && indexPath.section == selectedSection)
    {
        // Add the edition view height
        height += 65.0;
    }
    
    return height;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [recentsDataSource tableView:self.recentsTableView numberOfRowsInSection:collectionView.tag];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    RoomCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:RoomCollectionViewCell.defaultReuseIdentifier
                                                                                 forIndexPath:indexPath];
    
    id<MXKRecentCellDataStoring> cellData = [recentsDataSource cellDataAtIndexPath:[NSIndexPath indexPathForRow:indexPath.item inSection:collectionView.tag]];
    
    if (cellData)
    {
        [cell render:cellData];
        cell.tag = indexPath.item;
        cell.collectionViewTag = collectionView.tag;
        
        if (selectedCollectionViewContentOffset != -1 && collectionView.tag == selectedSection)
        {
            if (collectionView.contentOffset.x != selectedCollectionViewContentOffset)
            {
                // Force here the content offset of the collection in which the edited cell is displayed.
                // Indeed because of the table view cell height change the collection view scrolls at the beginning by default (on iOS < 10).
                collectionView.contentOffset = CGPointMake(selectedCollectionViewContentOffset, 0) ;
            }
            
            if (editedRoomId)
            {
                // Scroll the collection view in order to fully display the edited cell.
                NSIndexPath *indexPath = [self.dataSource cellIndexPathWithRoomId:editedRoomId andMatrixSession:self.mainSession];
                indexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:0];
                [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
                selectedCollectionViewContentOffset = collectionView.contentOffset.x;
            }
            else
            {
                // The edition mode is left now, remove the last stored values.
                selectedSection = -1;
                selectedCollectionViewContentOffset = -1;
            }
        }
        
        // Edition mode?
        if (editedRoomId)
        {
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCollectionViewCellTap:)];
            [cell addGestureRecognizer:tapGesture];
            
            if ([cellData.roomSummary.roomId isEqualToString:editedRoomId])
            {
                cell.editionArrowView.hidden = NO;
            }
        }
        else
        {
            // Add long tap gesture recognizer.
            UILongPressGestureRecognizer *cellLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onCollectionViewCellLongPress:)];
            [cell addGestureRecognizer:cellLongPressGesture];
        }
    }
    
    cell.backgroundColor = kRiotPrimaryBgColor;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        RoomCollectionViewCell *roomCollectionViewCell = (RoomCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
        
        id<MXKRecentCellDataStoring> renderedCellData = (id<MXKRecentCellDataStoring>)roomCollectionViewCell.renderedCellData;
        
        [self.delegate recentListViewController:self didSelectRoom:renderedCellData.roomSummary.roomId inMatrixSession:renderedCellData.roomSummary.room.mxSession];
    }
    
    // Hide the keyboard when user select a room
    // do not hide the searchBar until the view controller disappear
    // on tablets / iphone 6+, the user could expect to search again while looking at a room
    [self.recentsSearchBar resignFirstResponder];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [RoomCollectionViewCell defaultCellSize];
}

#pragma mark - Gesture Recognizer

- (void)onCollectionViewCellLongPress:(UIGestureRecognizer*)gestureRecognizer
{
    RoomCollectionViewCell *selectedCell;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        UIView *view = gestureRecognizer.view;
        if ([view isKindOfClass:[RoomCollectionViewCell class]])
        {
            selectedCell = (RoomCollectionViewCell*)view;
            
            MXRoom* room = [self.dataSource getRoomAtIndexPath:[NSIndexPath indexPathForRow:selectedCell.tag inSection:selectedCell.collectionViewTag]];
            
            if (room)
            {
                // Display no action for the invited room
                if (room.summary.membership == MXMembershipInvite)
                {
                    return;
                }
                
                // Store the identifier of the room related to the edited cell.
                selectedRoomId = room.roomId;
                // Store the concerned section
                selectedCollectionViewContentOffset = -1;
                selectedSection = selectedCell.collectionViewTag;
                
                // Store the current content offset of the selected collection before refreshing.
                NSIndexPath *tableViewCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:selectedSection];
                TableViewCellWithCollectionView *tableViewCellWithCollectionView = [self.recentsTableView cellForRowAtIndexPath:tableViewCellIndexPath];
                CGFloat selectedCollectionViewContentOffsetCpy = tableViewCellWithCollectionView.collectionView.contentOffset.x;
                
                [self refreshRecentsTable];
                
                // Make visible the edited cell
                tableViewCellWithCollectionView = [self.recentsTableView cellForRowAtIndexPath:tableViewCellIndexPath];
                NSIndexPath *collectionViewCellIndexPath = [self.dataSource cellIndexPathWithRoomId:selectedRoomId andMatrixSession:room.mxSession];
                collectionViewCellIndexPath = [NSIndexPath indexPathForItem:collectionViewCellIndexPath.item inSection:0];
                UICollectionViewCell *roomCollectionViewCell = [tableViewCellWithCollectionView.collectionView cellForItemAtIndexPath:collectionViewCellIndexPath];
                if (roomCollectionViewCell)
                {
                    [tableViewCellWithCollectionView.collectionView scrollRectToVisible:roomCollectionViewCell.frame animated:YES];
                }
                else
                {
                    // On iOS < 10, the collection view scrolls to the beginning during the table refresh.
                    // We store here the actual content offset, used during the collection view loading.
                    selectedCollectionViewContentOffset = selectedCollectionViewContentOffsetCpy;
                }  
                
                [self.recentsTableView scrollRectToVisible:tableViewCellWithCollectionView.frame animated:YES];

                // Disable table view scrolling, and defined the swipe gesture recognizers used to cancel the edition mode
                self.recentsTableView.scrollEnabled = NO;
                horizontalSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onTableViewSwipe:)];
                [horizontalSwipeGestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight)];
                [self.recentsTableView addGestureRecognizer:horizontalSwipeGestureRecognizer];
                verticalSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onTableViewSwipe:)];
                [verticalSwipeGestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown)];
                [self.recentsTableView addGestureRecognizer:verticalSwipeGestureRecognizer];
            }
        }
    }
}

- (void)onCollectionViewCellTap:(UIGestureRecognizer*)gestureRecognizer
{
    [self cancelEditionMode:YES];
}

- (void)onTableViewSwipe:(UIGestureRecognizer*)gestureRecognizer
{
    [self cancelEditionMode:YES];
}

#pragma mark - Action

- (IBAction)onDirectChatButtonPressed:(id)sender
{
    if (editedRoomId)
    {
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            UIButton *button = (UIButton*)sender;
            [self makeDirectEditedRoom:!button.tag];
        }
    }
}

- (IBAction)onNotificationsButtonPressed:(id)sender
{
    if (editedRoomId)
    {
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            UIButton *button = (UIButton*)sender;
            [self muteEditedRoomNotifications:!button.tag];
        }
    }
}

- (IBAction)onFavouriteButtonPressed:(id)sender
{
    if (editedRoomId)
    {
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            UIButton *button = (UIButton*)sender;
            if (button.tag)
            {
                [self updateEditedRoomTag:nil];
            }
            else
            {
                [self updateEditedRoomTag:kMXRoomTagFavourite];
            }
        }
    }
}

- (IBAction)onPriorityButtonPressed:(id)sender
{
    if (editedRoomId)
    {
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            UIButton *button = (UIButton*)sender;
            if (button.tag)
            {
                [self updateEditedRoomTag:nil];
            }
            else
            {
                [self updateEditedRoomTag:kMXRoomTagLowPriority];
            }
        }
    }
}

- (IBAction)onLeaveButtonPressed:(id)sender
{
    [self leaveEditedRoom];
}

@end
