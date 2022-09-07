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

#import "GeneratedInterface-Swift.h"

#import "RecentsDataSource.h"

#import "TableViewCellWithCollectionView.h"
#import "RoomCollectionViewCell.h"

#import "MXRoom+Riot.h"

@interface HomeViewController () <SecureBackupSetupCoordinatorBridgePresenterDelegate, SpaceMembersCoordinatorBridgePresenterDelegate>
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

@property (nonatomic, strong) SecureBackupSetupCoordinatorBridgePresenter *secureBackupSetupCoordinatorBridgePresenter;
@property (nonatomic, strong) SecureBackupBannerCell *secureBackupBannerPrototypeCell;

@property (nonatomic, strong) CrossSigningSetupBannerCell *keyVerificationSetupBannerPrototypeCell;
@property (nonatomic, strong) CrossSigningSetupCoordinatorBridgePresenter *crossSigningSetupCoordinatorBridgePresenter;

@property (nonatomic, assign, readwrite) BOOL roomListDataReady;
@property (nonatomic, strong) MXThrottler *collectionViewPaginationThrottler;

@property(nonatomic) SpaceMembersCoordinatorBridgePresenter *spaceMembersCoordinatorBridgePresenter;

@end

@implementation HomeViewController

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    HomeViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];
    return viewController;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    selectedSection = -1;
    selectedRoomId = nil;
    selectedCollectionViewContentOffset = -1;
    
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenHome];
    self.collectionViewPaginationThrottler = [[MXThrottler alloc] initWithMinimumDelay:0.1];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!BuildSettings.newAppLayoutEnabled)
    {
        [self.tabBarController vc_setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeNever];
    }
    
    self.roomListDataReady = NO;
    
    self.view.accessibilityIdentifier = @"HomeVCView";
    self.recentsTableView.accessibilityIdentifier = @"HomeVCTableView";
    
    // Tag the recents table with the its recents data source mode.
    // This will be used by the shared RecentsDataSource instance for sanity checks (see UITableViewDataSource methods).
    self.recentsTableView.tag = self.recentsDataSourceMode;
    self.recentsTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    // Add the (+) button programmatically
    [self addFabButton];
    
    // Register table view cells used for rooms collection.
    [self registerCellsWithCollectionViews];

    // Change the table data source. It must be the home view controller itself.
    self.recentsTableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!BuildSettings.newAppLayoutEnabled)
    {
        [ThemeService.shared.theme applyStyleOnNavigationBar:[AppDelegate theDelegate].masterTabBarController.navigationController.navigationBar];

        [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = ThemeService.shared.theme.tintColor;
    }
    
    if (recentsDataSource.recentsDataSourceMode != self.recentsDataSourceMode)
    {
        // Take the lead on the shared data source.
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:self.recentsDataSourceMode];
        
        // Reset filtering on the shared data source when switching tabs
        [recentsDataSource searchWithPatterns:nil];
        [self.recentsSearchBar setText:nil];
    }
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

- (void)destroy
{
    [super destroy];
}

- (SecureBackupBannerCell *)secureBackupBannerPrototypeCell
{
    if (!_secureBackupBannerPrototypeCell)
    {
        _secureBackupBannerPrototypeCell = [self.recentsTableView dequeueReusableCellWithIdentifier:SecureBackupBannerCell.defaultReuseIdentifier];
    }
    return _secureBackupBannerPrototypeCell;
}

- (CrossSigningSetupBannerCell *)keyVerificationSetupBannerPrototypeCell
{
    if (!_keyVerificationSetupBannerPrototypeCell)
    {
        _keyVerificationSetupBannerPrototypeCell = [self.recentsTableView dequeueReusableCellWithIdentifier:CrossSigningSetupBannerCell.defaultReuseIdentifier];
    }
    return _keyVerificationSetupBannerPrototypeCell;
}

- (void)presentSecureBackupSetup
{
    SecureBackupSetupCoordinatorBridgePresenter *keyBackupSetupCoordinatorBridgePresenter = [[SecureBackupSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession allowOverwrite:NO];
    keyBackupSetupCoordinatorBridgePresenter.delegate = self;

    [keyBackupSetupCoordinatorBridgePresenter presentFrom:self animated:YES];

    self.secureBackupSetupCoordinatorBridgePresenter = keyBackupSetupCoordinatorBridgePresenter;
}

- (void)addFabButton
{
    plusButtonImageView = [self vc_addFABWithImage:AssetImages.plusFloatingAction.image
                                            target:self
                                            action:@selector(onPlusButtonPressed)];
}

- (RecentsDataSourceMode)recentsDataSourceMode
{
    return RecentsDataSourceModeHome;
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
    if (recentsDataSource.recentsDataSourceMode != self.recentsDataSourceMode)
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

- (void)onMatrixSessionChange
{
    [super onMatrixSessionChange];
    
    [self updateEmptyView];
}

- (void)startChat {
    if (recentsDataSource.currentSpace)
    {
        self.spaceMembersCoordinatorBridgePresenter = [[SpaceMembersCoordinatorBridgePresenter alloc] initWithUserSessionsService:[UserSessionsService shared] session:self.mainSession spaceId:self.dataSource.currentSpace.spaceId];
        self.spaceMembersCoordinatorBridgePresenter.delegate = self;
        [self.spaceMembersCoordinatorBridgePresenter presentFrom:self animated:YES];
    }
    else
    {
        [super startChat];
    }
}

- (void)createNewRoom
{
    if (recentsDataSource.currentSpace) {
        [recentsDataSource.currentSpace canAddRoomWithCompletion:^(BOOL canAddRoom) {
            if (canAddRoom) {
                [super createNewRoom];
            } else {
                [[AppDelegate theDelegate] showAlertWithTitle:[VectorL10n roomRecentsCreateEmptyRoom]
                                                      message:[VectorL10n spacesAddRoomMissingPermissionMessage]];
            }
        }];
    } else {
        [super createNewRoom];
    }
}

#pragma mark - UITableViewDataSource

// Table view cells on the home screen contain nested collection views with their own data source and state.
// In order to preserve properties such as content offset of each collection view, the parent cells must
// be directly associated with each section, so that when getting dequed by the table view, the correct cell
// is reused, rather than cells getting randomly swapped around.
- (void)registerCellsWithCollectionViews
{
    for (NSNumber *section in self.sections) {
        NSString *cellIdentifier = [self cellIdentifierForSectionType:section.integerValue];
        [self.recentsTableView registerClass:TableViewCellWithCollectionView.class forCellReuseIdentifier:cellIdentifier];
    }
}

- (NSArray<NSNumber *> *)sections
{
    return @[
        @(RecentsDataSourceSectionTypeDirectory),
        @(RecentsDataSourceSectionTypeInvites),
        @(RecentsDataSourceSectionTypeFavorites),
        @(RecentsDataSourceSectionTypePeople),
        @(RecentsDataSourceSectionTypeConversation),
        @(RecentsDataSourceSectionTypeLowPriority),
        @(RecentsDataSourceSectionTypeServerNotice),
        @(RecentsDataSourceSectionTypeSuggestedRooms),
        @(RecentsDataSourceSectionTypeBreadcrumbs)
    ];
}

- (NSString *)cellIdentifierForSectionType:(RecentsDataSourceSectionType)sectionType
{
    // Create cell identifier unique to each semantic section, e.g. 'favorites' will have different cell
    // identifier to 'conversations'.
    return [NSString stringWithFormat:@"%@-%ld", TableViewCellWithCollectionView.defaultReuseIdentifier, sectionType];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the actual number of sections prepared in recents dataSource.
    return [recentsDataSource numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Edit the potential selected room (see `onCollectionViewCellLongPress`).
    editedRoomId = selectedRoomId;

    if ([recentsDataSource isSectionShrinkedAt:section])
    {
        return 0;
    }
    else
    {
        // Each rooms section is represented by only one collection view except for the all chats section.
        NSInteger index = [recentsDataSource.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeAllChats];
        if (section == index)
        {
            return [self.dataSource tableView:tableView numberOfRowsInSection:section];
        }
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = [recentsDataSource.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeAllChats];
    if (indexPath.section == index)
    {
        return [self.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }

    RecentsDataSourceSectionType sectionType = [recentsDataSource.sections sectionTypeForSectionIndex:indexPath.section];
    if ((sectionType == RecentsDataSourceSectionTypeConversation && !recentsDataSource.recentsListService.conversationRoomListData.counts.numberOfRooms)
        || (sectionType == RecentsDataSourceSectionTypePeople && !recentsDataSource.recentsListService.peopleRoomListData.counts.numberOfRooms)
        || (sectionType == RecentsDataSourceSectionTypeSecureBackupBanner)
        || (sectionType == RecentsDataSourceSectionTypeCrossSigningBanner)
        )
    {
        return [recentsDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    NSString *cellIdentifier = [self cellIdentifierForSectionType:sectionType];
    TableViewCellWithCollectionView *tableViewCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    tableViewCell.collectionView.tag = indexPath.section;
    [tableViewCell.collectionView registerClass:RoomCollectionViewCell.class forCellWithReuseIdentifier:RoomCollectionViewCell.defaultReuseIdentifier];
    tableViewCell.collectionView.delegate = self;
    tableViewCell.collectionView.dataSource = self;
    tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (editedRoomId)
    {
        UIColor *selectedColor = ThemeService.shared.theme.tintColor;
        UIColor *unselectedColor = ThemeService.shared.theme.tabBarUnselectedItemTintColor;
        
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
            tableViewCell.directChatImageView.image = AssetImages.roomActionDirectChat.image;
            tableViewCell.directChatImageView.tintColor = room.isDirect ? selectedColor : unselectedColor;
            
            tableViewCell.notificationsButton.tag = room.isMute || room.isMentionsOnly;
            [tableViewCell.notificationsButton addTarget:self action:@selector(onNotificationsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            if ([BuildSettings showNotificationsV2] && tableViewCell.notificationsButton.tag)
            {
                tableViewCell.notificationsImageView.image = AssetImages.roomActionNotificationMuted.image;
            }
            else
            {
                tableViewCell.notificationsImageView.image = AssetImages.roomActionNotification.image;
            }
            
            tableViewCell.notificationsImageView.tintColor = tableViewCell.notificationsButton.tag ? unselectedColor : selectedColor;
            
            // Get the room tag (use only the first one).
            MXRoomTag* currentTag = nil;
            if (room.accountData.tags)
            {
                NSArray<MXRoomTag*>* tags = room.accountData.tags.allValues;
                if (tags.count)
                {
                    currentTag = tags[0];
                }
            }
            
            tableViewCell.favouriteButton.tag = (currentTag && [kMXRoomTagFavourite isEqualToString:currentTag.name]);
            [tableViewCell.favouriteButton addTarget:self action:@selector(onFavouriteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            tableViewCell.favouriteImageView.image = AssetImages.roomActionFavourite.image;
            tableViewCell.favouriteImageView.tintColor = tableViewCell.favouriteButton.tag ? selectedColor : unselectedColor;
            
            tableViewCell.priorityButton.tag = (currentTag && [kMXRoomTagLowPriority isEqualToString:currentTag.name]);
            [tableViewCell.priorityButton addTarget:self action:@selector(onPriorityButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            tableViewCell.priorityImageView.image = tableViewCell.priorityButton.tag ? AssetImages.roomActionPriorityHigh.image : AssetImages.roomActionPriorityLow.image;
            tableViewCell.priorityImageView.tintColor = unselectedColor;
            
            [tableViewCell.leaveButton addTarget:self action:@selector(onLeaveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            tableViewCell.leaveImageView.image = AssetImages.roomActionLeave.image;
            tableViewCell.leaveImageView.tintColor = unselectedColor;
        }
    }
    
    return tableViewCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = [recentsDataSource.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeAllChats];
    if (indexPath.section == index)
    {
        return [self.dataSource tableView:tableView canEditRowAtIndexPath:indexPath];
    }

    return NO;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = [recentsDataSource.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeAllChats];
    if (indexPath.section == index)
    {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }

    RecentsDataSourceSectionType sectionType = [recentsDataSource.sections sectionTypeForSectionIndex:indexPath.section];
    if ((sectionType == RecentsDataSourceSectionTypeConversation && !recentsDataSource.recentsListService.conversationRoomListData.counts.numberOfRooms)
        || (sectionType == RecentsDataSourceSectionTypePeople && !recentsDataSource.recentsListService.peopleRoomListData.counts.numberOfRooms))
    {
        return [recentsDataSource cellHeightAtIndexPath:indexPath];
    }
    else if (sectionType == RecentsDataSourceSectionTypeSecureBackupBanner || sectionType == RecentsDataSourceSectionTypeCrossSigningBanner)
    {
        CGFloat height = 0.0;
        
        UITableViewCell *sizingCell;
        
        if (sectionType == RecentsDataSourceSectionTypeSecureBackupBanner)
        {
            SecureBackupBannerCell *secureBackupBannerCell = self.secureBackupBannerPrototypeCell;
            [secureBackupBannerCell configureFor:recentsDataSource.secureBackupBannerDisplay];
            sizingCell = secureBackupBannerCell;
        }
        else if (sectionType == RecentsDataSourceSectionTypeCrossSigningBanner)
        {
            sizingCell = self.keyVerificationSetupBannerPrototypeCell;
        }
        
        [sizingCell layoutIfNeeded];
        
        CGSize fittingSize = UILayoutFittingCompressedSize;
        CGFloat tableViewWidth = CGRectGetWidth(tableView.frame);
        CGFloat safeAreaWidth = MAX(tableView.safeAreaInsets.left, tableView.safeAreaInsets.right);
        
        fittingSize.width = tableViewWidth - safeAreaWidth;
        
        height = [sizingCell systemLayoutSizeFittingSize:fittingSize withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
        
        return height;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // No header in key banner section
    RecentsDataSourceSectionType sectionType = [recentsDataSource.sections sectionTypeForSectionIndex:section];
    if (sectionType == RecentsDataSourceSectionTypeSecureBackupBanner
        || sectionType == RecentsDataSourceSectionTypeCrossSigningBanner)
    {
        return 0.0;
    }
    else
    {
        return [(RecentsDataSource *)self.dataSource heightForHeaderInSection:section];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RecentsDataSourceSectionType sectionType = [recentsDataSource.sections sectionTypeForSectionIndex:indexPath.section];
    if (sectionType == RecentsDataSourceSectionTypeSecureBackupBanner)
    {
        switch (recentsDataSource.secureBackupBannerDisplay) {
            case SecureBackupBannerDisplaySetup:
                [self presentSecureBackupSetup];
                break;
            default:
                break;
        }
    }
    else if (sectionType == RecentsDataSourceSectionTypeCrossSigningBanner)
    {
        [self showCrossSigningSetup];
    }
    else if (sectionType == RecentsDataSourceSectionTypeAllChats)
    {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
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
            
            if ([cellData.roomIdentifier isEqualToString:editedRoomId])
            {
                cell.editionArrowView.hidden = NO;
            }
        }
        else
        {
            if (@available(iOS 13.0, *))
            {
                // Use context menu instead
            }
            else
            {
                // Add long tap gesture recognizer.
                UILongPressGestureRecognizer *cellLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onCollectionViewCellLongPress:)];
                [cell addGestureRecognizer:cellLongPressGesture];
            }
        }
    }
    
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger collectionViewSection = indexPath.section;
    if (collectionView.numberOfSections <= collectionViewSection)
    {
        return;
    }

    NSInteger numberOfItemsInSection = [collectionView numberOfItemsInSection:collectionViewSection];
    if (indexPath.item != numberOfItemsInSection - 1)
    {
        return;
    }
    
    [self.collectionViewPaginationThrottler throttle:^{
        NSInteger tableViewSection = collectionView.tag;
        [self->recentsDataSource paginateInSection:tableViewSection];
    }];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        RoomCollectionViewCell *roomCollectionViewCell = (RoomCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
        
        id<MXKRecentCellDataStoring> renderedCellData = (id<MXKRecentCellDataStoring>)roomCollectionViewCell.renderedCellData;
        
        if (renderedCellData.isSuggestedRoom)
        {
            [self.delegate recentListViewController:self
                             didSelectSuggestedRoom:renderedCellData.roomSummary.spaceChildInfo
                                               from:roomCollectionViewCell];
        }
        else
        {
            [self.delegate recentListViewController:self
                                      didSelectRoom:renderedCellData.roomIdentifier
                                    inMatrixSession:renderedCellData.mxSession];
        }
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
                CGFloat selectedCollectionViewContentOffsetCopy = tableViewCellWithCollectionView.collectionView.contentOffset.x;
                
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
                    selectedCollectionViewContentOffset = selectedCollectionViewContentOffsetCopy;
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
    UIButton *button = (UIButton*)sender;
    [self makeDirectEditedRoom:!button.tag];
}

- (IBAction)onNotificationsButtonPressed:(id)sender
{
    if ([BuildSettings showNotificationsV2])
    {
        [self changeEditedRoomNotificationSettings];
    }
    else
    {
        UIButton *button = (UIButton*)sender;
        [self muteEditedRoomNotifications:!button.tag];
    }
}

- (IBAction)onFavouriteButtonPressed:(id)sender
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

- (IBAction)onPriorityButtonPressed:(id)sender
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

- (IBAction)onLeaveButtonPressed:(id)sender
{
    [self leaveEditedRoom];
}

#pragma mark - SecureBackupSetupCoordinatorBridgePresenterDelegate

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidComplete:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self.secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.secureBackupSetupCoordinatorBridgePresenter = nil;
}

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidCancel:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self.secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.secureBackupSetupCoordinatorBridgePresenter = nil;
}

#pragma mark - Cross-signing setup

- (void)showCrossSigningSetup
{
    [self setupCrossSigningWithTitle:[VectorL10n crossSigningSetupBannerTitle] message:[VectorL10n securitySettingsUserPasswordDescription] success:^{
        
    } failure:^(NSError *error) {
        
    }];
}

- (void)setupCrossSigningWithTitle:(NSString*)title
                           message:(NSString*)message
                           success:(void (^)(void))success
                           failure:(void (^)(NSError *error))failure

{
    [self startActivityIndicator];
    self.view.userInteractionEnabled = NO;
    
    MXWeakify(self);
    
    void (^animationCompletion)(void) = ^void () {
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        self.view.userInteractionEnabled = YES;
        [self.crossSigningSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:^{}];
        self.crossSigningSetupCoordinatorBridgePresenter = nil;
    };
    
    CrossSigningSetupCoordinatorBridgePresenter *crossSigningSetupCoordinatorBridgePresenter = [[CrossSigningSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];
        
    [crossSigningSetupCoordinatorBridgePresenter presentWith:title
                                                     message:message
                                                        from:self
                                                    animated:YES
                                                     success:^{
        animationCompletion();
        
        // TODO: Remove this line and refresh key verification setup banner by listening to a local notification cross-signing state change (Add this behavior into the SDK).
        [self->recentsDataSource setDelegate:self andRecentsDataSourceMode:self.recentsDataSourceMode];
        [self refreshRecentsTable];
        
        success();
    } cancel:^{
        animationCompletion();
        failure(nil);
    } failure:^(NSError * _Nonnull error) {
        animationCompletion();
        [self refreshRecentsTable];
        [[AppDelegate theDelegate] showErrorAsAlert:error];
        failure(error);
    }];
    
    self.crossSigningSetupCoordinatorBridgePresenter = crossSigningSetupCoordinatorBridgePresenter;
}

#pragma mark - Empty view management

- (void)updateEmptyView
{
    MXUser *myUser = self.mainSession.myUser;
    NSString *displayName = myUser.displayname ?: myUser.userId;
    displayName = displayName ?: @"";
    
    NSString *appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    NSString *title = [VectorL10n homeEmptyViewTitle:appName :displayName];
    
    [self.emptyView fillWith:[self emptyViewArtwork]
                       title:title
             informationText:[VectorL10n homeEmptyViewInformation]];
}

- (UIImage*)emptyViewArtwork
{
    if (ThemeService.shared.isCurrentThemeDark)
    {
        return AssetImages.homeEmptyScreenArtworkDark.image;
    }
    else
    {
        return AssetImages.homeEmptyScreenArtwork.image;
    }
}

- (BOOL)shouldShowEmptyView
{
    // Do not present empty screen while searching
    if (recentsDataSource.searchPatternsList.count)
    {
        return NO;
    }
    
    // Check if some banners should be displayed
    if ([recentsDataSource.sections contains:RecentsDataSourceSectionTypeSecureBackupBanner]
        || [recentsDataSource.sections contains:RecentsDataSourceSectionTypeCrossSigningBanner])
    {
        return NO;
    }
    
    // Otherwise check the number of items to display
    return recentsDataSource.totalVisibleItemCount == 0;
}

#pragma mark - SpaceMembersCoordinatorBridgePresenterDelegate

- (void)spaceMembersCoordinatorBridgePresenterDelegateDidComplete:(SpaceMembersCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        self.spaceMembersCoordinatorBridgePresenter = nil;
    }];
}

#pragma mark - Context Menu

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0))
{
    RecentsDataSourceSectionType sectionType = [recentsDataSource.sections sectionTypeForSectionIndex:indexPath.section];
    if (sectionType == RecentsDataSourceSectionTypeAllChats)
    {
        return [super tableView:tableView contextMenuConfigurationForRowAtIndexPath:indexPath point:point];
    }
    
    return nil;
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0))
{
    id<MXKRecentCellDataStoring> cellData = [recentsDataSource cellDataAtIndexPath:[NSIndexPath indexPathForRow:indexPath.item inSection:collectionView.tag]];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    if (!cellData || !cell)
    {
        return nil;
    }
    
    return [self.contextMenuProvider contextMenuConfigurationWith:cellData from:cell session:self.dataSource.mxSession];
}

- (void)collectionView:(UICollectionView *)collectionView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0))
{
    NSString *roomId = [self.contextMenuProvider roomIdFrom:configuration.identifier];
    
    if (!roomId)
    {
        self.recentsUpdateEnabled = YES;
        return;
    }

    [animator addCompletion:^{
        self.recentsUpdateEnabled = YES;
        [self showRoomWithRoomId:roomId inMatrixSession:self.mainSession];
    }];
}

- (UITargetedPreview *)collectionView:(UICollectionView *)collectionView previewForDismissingContextMenuWithConfiguration:(UIContextMenuConfiguration *)configuration API_AVAILABLE(ios(13.0))
{
    self.recentsUpdateEnabled = YES;
    return nil;
}

@end
