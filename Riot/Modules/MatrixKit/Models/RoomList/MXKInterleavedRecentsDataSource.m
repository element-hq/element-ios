/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKInterleavedRecentsDataSource.h"

#import "MXKInterleavedRecentTableViewCell.h"

#import "MXKAccountManager.h"

#import "NSBundle+MatrixKit.h"

@interface MXKInterleavedRecentsDataSource ()
{
    /**
     The interleaved recents: cell data served by `MXKInterleavedRecentsDataSource`.
     */
    NSMutableArray *interleavedCellDataArray;
}

@end

@implementation MXKInterleavedRecentsDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        interleavedCellDataArray = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Override MXKDataSource

- (void)destroy
{
    interleavedCellDataArray = nil;
    
    [super destroy];
}

#pragma mark - Override MXKRecentsDataSource

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView*)tableView
{
    UIView *sectionHeader = nil;
    
    if (displayedRecentsDataSourceArray.count > 1 && section == 0)
    {
        sectionHeader = [[UIView alloc] initWithFrame:frame];
        sectionHeader.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
        CGFloat btnWidth = frame.size.width / displayedRecentsDataSourceArray.count;
        UIButton *previousShrinkButton;
        
        for (NSInteger index = 0; index < displayedRecentsDataSourceArray.count; index++)
        {
            MXKSessionRecentsDataSource *recentsDataSource = [displayedRecentsDataSourceArray objectAtIndex:index];
            NSString* btnTitle = recentsDataSource.mxSession.myUser.userId;
            
            // Add shrink button
            UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
            CGRect btnFrame = CGRectMake(index * btnWidth, 0, btnWidth, sectionHeader.frame.size.height);
            shrinkButton.frame = btnFrame;
            shrinkButton.backgroundColor = [UIColor clearColor];
            
            [shrinkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            shrinkButton.tag = index;
            [sectionHeader addSubview:shrinkButton];
            sectionHeader.userInteractionEnabled = YES;
            
            // Set shrink button constraints
            NSLayoutConstraint *leftConstraint;
            NSLayoutConstraint *widthConstraint;
            shrinkButton.translatesAutoresizingMaskIntoConstraints = NO;
            if (!previousShrinkButton)
            {
                leftConstraint = [NSLayoutConstraint constraintWithItem:shrinkButton
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:sectionHeader
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1
                                                               constant:0];
                widthConstraint = [NSLayoutConstraint constraintWithItem:shrinkButton
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:sectionHeader
                                                               attribute:NSLayoutAttributeWidth
                                                              multiplier:(1.0 /displayedRecentsDataSourceArray.count)
                                                                constant:0];
            }
            else
            {
                leftConstraint = [NSLayoutConstraint constraintWithItem:shrinkButton
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:previousShrinkButton
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1
                                                               constant:0];
                widthConstraint = [NSLayoutConstraint constraintWithItem:shrinkButton
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:previousShrinkButton
                                                               attribute:NSLayoutAttributeWidth
                                                              multiplier:1
                                                                constant:0];
            }
            [NSLayoutConstraint activateConstraints:@[leftConstraint, widthConstraint]];
            previousShrinkButton = shrinkButton;
            
            // Add shrink icon
            UIImage *chevron;
            if ([shrinkedRecentsDataSourceArray indexOfObject:recentsDataSource] != NSNotFound)
            {
                chevron = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"disclosure"];
            }
            else
            {
                chevron = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"shrink"];
            }
            UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevron];
            if ([shrinkedRecentsDataSourceArray indexOfObject:recentsDataSource] == NSNotFound)
            {
                // Display the tint color of the user
                MXKAccount *account = [[MXKAccountManager sharedManager] accountForUserId:recentsDataSource.mxSession.myUser.userId];
                if (account)
                {
                    chevronView.backgroundColor = account.userTintColor;
                }
                else
                {
                    chevronView.backgroundColor = [UIColor clearColor];
                }
            }
            else
            {
                chevronView.backgroundColor = [UIColor lightGrayColor];
            }
            chevronView.contentMode = UIViewContentModeCenter;
            frame = chevronView.frame;
            frame.size.width = frame.size.height = shrinkButton.frame.size.height - 10;
            frame.origin.x = shrinkButton.frame.size.width - frame.size.width - 8;
            frame.origin.y = (shrinkButton.frame.size.height - frame.size.height) / 2;
            chevronView.frame = frame;
            [shrinkButton addSubview:chevronView];
            chevronView.autoresizingMask |= (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
            
            // Add label
            frame = shrinkButton.frame;
            frame.origin.x = 5;
            frame.origin.y = 5;
            frame.size.width = chevronView.frame.origin.x - 10;
            frame.size.height -= 10;
            UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
            headerLabel.font = [UIFont boldSystemFontOfSize:16];
            headerLabel.backgroundColor = [UIColor clearColor];
            headerLabel.text = btnTitle;
            [shrinkButton addSubview:headerLabel];
            headerLabel.autoresizingMask |= (UIViewAutoresizingFlexibleWidth);
        }
    }
    
    return sectionHeader;
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKRecentCellDataStoring> cellData = nil;
    
    // Only one section is handled by this data source
    if (indexPath.section == 0)
    {
        // Consider first the case where there is only one data source (no interleaving).
        if (displayedRecentsDataSourceArray.count == 1)
        {
            MXKSessionRecentsDataSource *recentsDataSource = displayedRecentsDataSourceArray.firstObject;
            cellData = [recentsDataSource cellDataAtIndex:indexPath.row];
        }
        // Else all the cells have been interleaved.
        else if (indexPath.row < interleavedCellDataArray.count)
        {
            cellData = interleavedCellDataArray[indexPath.row];
        }
    }
    
    return cellData;
}

- (CGFloat)cellHeightAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0;
    
    // Only one section is handled by this data source
    if (indexPath.section == 0)
    {
        // Consider first the case where there is only one data source (no interleaving).
        if (displayedRecentsDataSourceArray.count == 1)
        {
            MXKSessionRecentsDataSource *recentsDataSource = displayedRecentsDataSourceArray.firstObject;
            height = [recentsDataSource cellHeightAtIndex:indexPath.row];
        }
        // Else all the cells have been interleaved.
        else if (indexPath.row < interleavedCellDataArray.count)
        {
            id<MXKRecentCellDataStoring> recentCellData = interleavedCellDataArray[indexPath.row];
            
            // Select the related recent data source
            MXKDataSource *dataSource = recentCellData.dataSource;
            if ([dataSource isKindOfClass:[MXKSessionRecentsDataSource class]])
            {
                MXKSessionRecentsDataSource *recentsDataSource = (MXKSessionRecentsDataSource*)dataSource;
                // Count the index of this cell data in original data source array
                NSInteger rank = 0;
                for (NSInteger index = 0; index < indexPath.row; index++)
                {
                    id<MXKRecentCellDataStoring> cellData = interleavedCellDataArray[index];
                    if (cellData.roomSummary == recentCellData.roomSummary)
                    {
                        rank++;
                    }
                }
                
                height = [recentsDataSource cellHeightAtIndex:rank];
            }
        }
    }
    
    return height;
}

- (NSIndexPath*)cellIndexPathWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)matrixSession
{
    NSIndexPath *indexPath = nil;
    
    // Consider first the case where there is only one data source (no interleaving).
    if (displayedRecentsDataSourceArray.count == 1)
    {
        MXKSessionRecentsDataSource *recentsDataSource = displayedRecentsDataSourceArray.firstObject;
        if (recentsDataSource.mxSession == matrixSession)
        {
            // Look for the cell
            for (NSInteger index = 0; index < recentsDataSource.numberOfCells; index ++)
            {
                id<MXKRecentCellDataStoring> recentCellData = [recentsDataSource cellDataAtIndex:index];
                if ([roomId isEqualToString:recentCellData.roomIdentifier])
                {
                    // Got it
                    indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    break;
                }
            }
        }
    }
    else
    {
        // Look for the right data source
        for (MXKSessionRecentsDataSource *recentsDataSource in displayedRecentsDataSourceArray)
        {
            if (recentsDataSource.mxSession == matrixSession)
            {
                // Check whether the source is not shrinked
                if ([shrinkedRecentsDataSourceArray indexOfObject:recentsDataSource] == NSNotFound)
                {
                    // Look for the cell
                    for (NSInteger index = 0; index < interleavedCellDataArray.count; index ++)
                    {
                        id<MXKRecentCellDataStoring> recentCellData = interleavedCellDataArray[index];
                        if ([roomId isEqualToString:recentCellData.roomIdentifier])
                        {
                            // Got it
                            indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                            break;
                        }
                    }
                }
                break;
            }
        }
    }
    
    return indexPath;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Check whether all data sources are ready before rendering recents
    if (self.state == MXKDataSourceStateReady)
    {
        // Only one section is handled by this data source.
        return (displayedRecentsDataSourceArray.count ? 1 : 0);
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Consider first the case where there is only one data source (no interleaving).
    if (displayedRecentsDataSourceArray.count == 1)
    {
        MXKSessionRecentsDataSource *recentsDataSource = displayedRecentsDataSourceArray.firstObject;
        return recentsDataSource.numberOfCells;
    }
    
    return interleavedCellDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKRecentCellDataStoring> roomData = [self cellDataAtIndexPath:indexPath];
    if (roomData && self.delegate)
    {
        NSString *cellIdentifier = [self.delegate cellReuseIdentifierForCellData:roomData];
        if (cellIdentifier)
        {
            UITableViewCell<MXKCellRendering> *cell  = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            
            // Make sure we listen to user actions on the cell
            cell.delegate = self;
            
            // Make the bubble display the data
            [cell render:roomData];
            
            // Clear the user flag, if only one recents list is available
            if (displayedRecentsDataSourceArray.count == 1 && [cell isKindOfClass:[MXKInterleavedRecentTableViewCell class]])
            {
                ((MXKInterleavedRecentTableViewCell*)cell).userFlag.backgroundColor = [UIColor clearColor];
            }
            
            return cell;
        }
    }
    
    // Return a fake cell to prevent app from crashing.
    return [[UITableViewCell alloc] init];
}

#pragma mark - MXKDataSourceDelegate

- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id)changes
{
    // Consider first the case where there is only one data source (no interleaving).
    if (displayedRecentsDataSourceArray.count == 1)
    {
        // Flush interleaved cells array, we will refer directly to the cell data of the unique data source.
        [interleavedCellDataArray removeAllObjects];
    }
    else
    {
        // Handle here the specific case where a second source is just added.
        // The empty interleaved cells array has to be prefilled with the cell data of the other source (except if this other source is shrinked).
        if (!interleavedCellDataArray.count && displayedRecentsDataSourceArray.count == 2)
        {
            // This is the first interleaving, look for the other source
            MXKSessionRecentsDataSource *recentsDataSource = displayedRecentsDataSourceArray.firstObject;
            if (recentsDataSource == dataSource)
            {
                recentsDataSource = displayedRecentsDataSourceArray.lastObject;
            }
            
            if ([shrinkedRecentsDataSourceArray indexOfObject:recentsDataSource] == NSNotFound)
            {
                // Report all cell data
                for (NSInteger index = 0; index < recentsDataSource.numberOfCells; index ++)
                {
                    [interleavedCellDataArray addObject:[recentsDataSource cellDataAtIndex:index]];
                }
            }
        }
        
        // Update now interleaved cells array, TODO take into account 'changes' parameter
        MXKSessionRecentsDataSource *updateRecentsDataSource = (MXKSessionRecentsDataSource*)dataSource;
        NSInteger numberOfUpdatedCells = 0;
        // Check whether this dataSource is used
        if ([displayedRecentsDataSourceArray indexOfObject:dataSource] != NSNotFound && [shrinkedRecentsDataSourceArray indexOfObject:dataSource] == NSNotFound)
        {
            numberOfUpdatedCells = updateRecentsDataSource.numberOfCells;
        }
        
        NSInteger currentCellIndex = 0;
        NSInteger updatedCellIndex = 0;
        id<MXKRecentCellDataStoring> updatedCellData = nil;
        
        if (numberOfUpdatedCells)
        {
            updatedCellData = [updateRecentsDataSource cellDataAtIndex:updatedCellIndex++];
        }
        
        // Review all cell data items of the current list
        while (currentCellIndex < interleavedCellDataArray.count)
        {
            id<MXKRecentCellDataStoring> currentCellData = interleavedCellDataArray[currentCellIndex];
            
            // Remove existing cell data of the updated data source
            if (currentCellData.dataSource == dataSource)
            {
                [interleavedCellDataArray removeObjectAtIndex:currentCellIndex];
            }
            else
            {
                while (updatedCellData && (updatedCellData.roomSummary.lastMessage.originServerTs > currentCellData.roomSummary.lastMessage.originServerTs))
                {
                    [interleavedCellDataArray insertObject:updatedCellData atIndex:currentCellIndex++];
                    updatedCellData = [updateRecentsDataSource cellDataAtIndex:updatedCellIndex++];
                }
                
                currentCellIndex++;
            }
        }
        
        while (updatedCellData)
        {
            [interleavedCellDataArray addObject:updatedCellData];
            updatedCellData = [updateRecentsDataSource cellDataAtIndex:updatedCellIndex++];
        }
    }
    
    // Call super to keep update readyRecentsDataSourceArray.
    [super dataSource:dataSource didCellChange:changes];
}

@end
