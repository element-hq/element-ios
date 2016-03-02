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
#import "RoomBubbleCellData.h"
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingTextMsgBubbleCell.h"

#import "RoomViewController.h"
#import "RoomDataSource.h"

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

@interface RoomSearchViewController ()
{
    // The event selected in the search results
    MXEvent *selectedEvent;
}

@end

@implementation RoomSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];

    // Hide line separators of empty cells
    self.searchTableView.tableFooterView = [[UIView alloc] init];

    // Reuse cells from the RoomViewController to display results
    [self.searchTableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.searchTableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];

    // Add the Vector background image when search bar is empty
    [self addBackgroundImageViewToView:self.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Enable the search field at the screen opening
    if (self.searchBar.text.length == 0)
    {
        [self showSearch:animated];
    }
}

#pragma mark - Override MXKViewController

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    [self setKeyboardHeightForBackgroundImage:keyboardHeight];

    [super setKeyboardHeight:keyboardHeight];
}

#pragma mark - Override UIViewController+VectorSearch

- (void)setKeyboardHeightForBackgroundImage:(CGFloat)keyboardHeight
{
    [super setKeyboardHeightForBackgroundImage:keyboardHeight];

    // Do not show the bubbles image if there are results already displayed
    if (self.dataSource.serverCount)
    {
        self.backgroundImageView.hidden = YES;
    }
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar2
{
    [super searchBarSearchButtonClicked:searchBar2];

    if (searchBar2.text.length)
    {
        self.backgroundImageView.hidden = YES;
    }
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Data in the cells are actually Vector RoomBubbleCellData
    RoomBubbleCellData *cellData = (RoomBubbleCellData*)[self.dataSource cellDataAtIndex:indexPath.row];
    selectedEvent = cellData.bubbleComponents[0].event;

    [self.searchBar resignFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Open the RoomViewController
    [self performSegueWithIdentifier:@"showTimeline" sender:self];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];

    if ([[segue identifier] isEqualToString:@"showTimeline"])
    {
        RoomViewController *roomViewController = segue.destinationViewController;

        RoomDataSource *roomDataSource = [[RoomDataSource alloc] initWithRoomId:selectedEvent.roomId andInitialEventId:selectedEvent.eventId andMatrixSession:self.dataSource.mxSession];
        [roomDataSource finalizeInitialization];

        [roomViewController displayRoom:roomDataSource];
    }
}

@end
