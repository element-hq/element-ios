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

#import "RoomSearchViewController.h"

#import "UIViewController+VectorSearch.h"

// Use RoomViewController cells to display results
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingTextMsgBubbleCell.h"


@implementation RoomSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Reuse cells from the RoomViewController to display results
    [self.searchTableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.searchTableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Enable the search field at the screen opening
    [self showSearch:animated];
}

#pragma mark - Override UIViewController+VectorSearch

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar2
{
    [super searchBarSearchButtonClicked:searchBar2];

    // Make the search
    [self.dataSource searchMessageText:searchBar2.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar2
{
    // Leave the screen
    [super searchBarCancelButtonClicked:searchBar2];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    Class cellViewClass = nil;

    // Sanity check
    if ([cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;

        // Select the suitable table view cell class
        if (bubbleData.isAttachmentWithThumbnail)
        {
            cellViewClass = RoomIncomingAttachmentBubbleCell.class;
        }
        else
        {
            cellViewClass = RoomIncomingTextMsgBubbleCell.class;
        }
    }

    return cellViewClass;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    Class class = [self cellViewClassForCellData:cellData];

    if ([class respondsToSelector:@selector(defaultReuseIdentifier)])
    {
        return [class defaultReuseIdentifier];
    }

    return nil;
}

#pragma mark - Override UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // `MXKRoomBubbleTableViewCell` cells displayed by the `RoomViewController`
    // do not have line separators.
    // The +1 here is for the line separator which is displayed by `RoomSearchViewController`.
    return [super tableView:tableView heightForRowAtIndexPath:indexPath] + 1;
}

@end
