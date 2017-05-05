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

@interface HomeViewController ()
{
    RecentsDataSource *recentsDataSource;
}
@end

@implementation HomeViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.screenName = @"Home";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"HomeVCView";
    self.recentsTableView.accessibilityIdentifier = @"HomeVCTableView";
    
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
    
    if (recentsDataSource)
    {
        // Take the lead on the shared data source.
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeHome];
    }
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];
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

- (void)onPlusButtonPressed
{
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismiss:NO];
    
    currentAlert = [[MXKAlert alloc] initWithTitle:nil message:nil style:MXKAlertStyleActionSheet];
    
    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_recents_start_chat_with", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
        
        [strongSelf performSegueWithIdentifier:@"presentStartChat" sender:strongSelf];
    }];
    
    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_recents_create_empty_room", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
        
        [strongSelf createAnEmptyRoom];
    }];

    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_recents_join_room", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;

        [strongSelf joinARoom];
    }];

    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
    }];
    
    currentAlert.sourceView = plusButtonImageView;
    
    currentAlert.mxkAccessibilityIdentifier = @"HomeVCCreateRoomAlert";
    [currentAlert showInViewController:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the actual number of sections prepared in recents dataSource.
    return [recentsDataSource numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Each rooms section is represented by only one collection view.
    return 1;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section
{
    // Keep the recents data source informations on the section headers.
    return [recentsDataSource heightForHeaderInSection:section];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    // Keep the recents data source informations on the section headers.
    return [recentsDataSource titleForHeaderInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == recentsDataSource.conversationSection && !recentsDataSource.conversationCellDataArray.count)
    {
        MXKTableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
        if (!tableViewCell)
        {
            tableViewCell = [[MXKTableViewCell alloc] init];
            tableViewCell.textLabel.textColor = kRiotTextColorGray;
            tableViewCell.textLabel.font = [UIFont systemFontOfSize:15.0];
            tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        // Check whether a search session is in progress
        if (recentsDataSource.searchPatternsList)
        {
            tableViewCell.textLabel.text = NSLocalizedStringFromTable(@"search_no_result", @"Vector", nil);
        }
        else
        {
            tableViewCell.textLabel.text = NSLocalizedStringFromTable(@"room_recents_no_conversation", @"Vector", nil);
        }
        
        return tableViewCell;
    }
    
    TableViewCellWithCollectionView *tableViewCell = [tableView dequeueReusableCellWithIdentifier:TableViewCellWithCollectionView.defaultReuseIdentifier forIndexPath:indexPath];
    tableViewCell.collectionView.tag = indexPath.section;
    [tableViewCell.collectionView registerClass:RoomCollectionViewCell.class forCellWithReuseIdentifier:RoomCollectionViewCell.defaultReuseIdentifier];
    tableViewCell.collectionView.delegate = self;
    tableViewCell.collectionView.dataSource = self;
    tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return tableViewCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == recentsDataSource.conversationSection && !recentsDataSource.conversationCellDataArray.count)
    {
        return 50.0;
    }
    
    // Return the fixed height of the collection view cell used to display a room.
    return [RoomCollectionViewCell defaultCellSize].height;
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
        
        //TODO: add long tap gesture recognizer.
//        UILongPressGestureRecognizer *cellLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onCollectionViewCellLongPress:)];
//        [cell addGestureRecognizer:cellLongPressGesture];
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        id<MXKRecentCellDataStoring> cellData = [recentsDataSource cellDataAtIndexPath:[NSIndexPath indexPathForRow:indexPath.item inSection:collectionView.tag]];
        
        [self.delegate recentListViewController:self didSelectRoom:cellData.roomSummary.roomId inMatrixSession:cellData.roomSummary.room.mxSession];
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

@end
