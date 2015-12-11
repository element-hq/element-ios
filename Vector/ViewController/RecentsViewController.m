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

#import "RecentsViewController.h"
#import "RecentsDataSource.h"
#import "RecentTableViewCell.h"

#import "RageShakeManager.h"

#import "NSBundle+MatrixKit.h"

#import "HomeViewController.h"
#import "RoomViewController.h"

#import "VectorDesignValues.h"

#import "InviteRecentTableViewCell.h"

@interface RecentsViewController ()
{
    // Recents refresh handling
    BOOL shouldScrollToTopOnRefresh;

    // The "parent" segmented view controller
    HomeViewController *homeViewController;
    
    // recents drag and drop management
    UIView *cellSnapshot;
}

@end

@implementation RecentsViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"recents", @"Vector", nil);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKRecentListViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Register here the customized cell view class used to render recents
    [self.recentsTableView registerNib:RecentTableViewCell.nib forCellReuseIdentifier:RecentTableViewCell.defaultReuseIdentifier];
    [self.recentsTableView registerNib:InviteRecentTableViewCell.nib forCellReuseIdentifier:InviteRecentTableViewCell.defaultReuseIdentifier];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onRecentsLongPress:)];
    [self.recentsTableView addGestureRecognizer:longPress];
}

- (void)destroy
{
    [super destroy];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.recentsTableView.editing = editing;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Deselect the current selected row, it will be restored on viewDidAppear (if any)
    NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
    if (indexPath)
    {
        [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Leave potential editing mode
    [self setEditing:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
    // Note: 'isCollapsed' property is available in UISplitViewController for iOS 8 and later.
    if (!self.splitViewController || ([self.splitViewController respondsToSelector:@selector(isCollapsed)] && self.splitViewController.isCollapsed))
    {
        // Release the current selected room (if any).
        //[self closeSelectedRoom];
    }
    else
    {
        // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
        // the selected room (if any) is highlighted.
        [self refreshCurrentSelectedCell:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark -

- (void)displayList:(MXKRecentsDataSource*)listDataSource fromHomeViewController:(HomeViewController*)homeViewController2
{
    [super displayList:listDataSource];
    homeViewController = homeViewController2;
}

#pragma mark - Internal methods

- (void)scrollToTop
{
    // Stop any scrolling effect before scrolling to the tableview top
    [UIView setAnimationsEnabled:NO];

    self.recentsTableView.contentOffset = CGPointMake(-self.recentsTableView.contentInset.left, -self.recentsTableView.contentInset.top);
    
    [UIView setAnimationsEnabled:YES];
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    if (homeViewController.currentRoomViewController)
    {
        // Look for the rank of this selected room in displayed recents
        currentSelectedCellIndexPath = [self.dataSource cellIndexPathWithRoomId:homeViewController.selectedRoomId andMatrixSession:homeViewController.selectedRoomSession];
    }

    if (currentSelectedCellIndexPath)
    {
        // Select the right row
        [self.recentsTableView selectRowAtIndexPath:currentSelectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        if (forceVisible)
        {
            // Scroll table view to make the selected row appear at second position
            NSInteger topCellIndexPathRow = currentSelectedCellIndexPath.row ? currentSelectedCellIndexPath.row - 1: currentSelectedCellIndexPath.row;
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:currentSelectedCellIndexPath.section];
            [self.recentsTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
    else
    {
        NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
        if (indexPath)
        {
            [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    id<MXKRecentCellDataStoring> cellDataStoring = (id<MXKRecentCellDataStoring> )cellData;
    
    if (NSNotFound == [cellDataStoring.recentsDataSource.mxSession.invitedRooms indexOfObject:cellDataStoring.roomDataSource.room])
    {
        return RecentTableViewCell.class;
    }
    else
    {
        return InviteRecentTableViewCell.class;
    }
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    id<MXKRecentCellDataStoring> cellDataStoring = (id<MXKRecentCellDataStoring> )cellData;
    
    if (NSNotFound == [cellDataStoring.recentsDataSource.mxSession.invitedRooms indexOfObject:cellDataStoring.roomDataSource.room])
    {
        return RecentTableViewCell.defaultReuseIdentifier;
    }
    else
    {
        return InviteRecentTableViewCell.defaultReuseIdentifier;
    }
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    if ([dataSource isKindOfClass:[RecentsDataSource class]])
    {
        RecentsDataSource* recentsDataSource = (RecentsDataSource*)dataSource;
    
        recentsDataSource.onRoomInvitationReject = ^(MXRoom* room) {
            
            [self.recentsTableView setEditing:NO];
            
            [room leave:^{
                [self.recentsTableView reloadData];
            } failure:^(NSError *error) {
                NSLog(@"[RecentsViewController] Failed to reject an invited room (%@) failed: %@", room.state.roomId, error);
            }];

        };
        
        recentsDataSource.onRoomInvitationAccept = ^(MXRoom* room) {
            [self.delegate recentListViewController:self didSelectRoom:room.state.roomId inMatrixSession:room.mxSession];
        };
    }

    
    [self.recentsTableView reloadData];
    
    if (shouldScrollToTopOnRefresh)
    {
        [self scrollToTop];
        shouldScrollToTopOnRefresh = NO;
    }
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side on screen,
    // the selected room (if any) is updated and kept visible.
    // Note: 'isCollapsed' property is available in UISplitViewController for iOS 8 and later.
    if (self.splitViewController && (![self.splitViewController respondsToSelector:@selector(isCollapsed)] || !self.splitViewController.isCollapsed))
    {
        [self refreshCurrentSelectedCell:YES];
    }
}

#pragma mark - swipe actions
static NSMutableDictionary* backgroundByImageNameDict;

- (UIColor*)getBackgroundColor:(NSString*)imageName
{
    UIColor* backgroundColor = VECTOR_LIGHT_GRAY_COLOR;
    
    if (!imageName)
    {
        return backgroundColor;
    }
    
    if (!backgroundByImageNameDict)
    {
        backgroundByImageNameDict = [[NSMutableDictionary alloc] init];
    }
    
    UIColor* bgColor = [backgroundByImageNameDict objectForKey:imageName];
    
    if (!bgColor)
    {
        CGFloat backgroundSide = 74.0;
        CGFloat sourceSide = 30.0;
        
        UIImageView* backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, backgroundSide, backgroundSide)];
        backgroundView.backgroundColor = backgroundColor;
        
        CGFloat offset = (backgroundSide - sourceSide) / 2.0f;
        
        UIImageView* resourceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(offset, offset, sourceSide, sourceSide)];
        resourceImageView.backgroundColor = [UIColor clearColor];
        resourceImageView.image = [MXKTools resizeImage:[UIImage imageNamed:imageName] toSize:CGSizeMake(sourceSide, sourceSide)];
        
        [backgroundView addSubview:resourceImageView];
        
        // Create a "canvas" (image context) to draw in.
        UIGraphicsBeginImageContextWithOptions(backgroundView.frame.size, NO, 0);
        
        // set to the top quality
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        [[backgroundView layer] renderInContext: UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

    
        bgColor = [[UIColor alloc] initWithPatternImage:image];
        [backgroundByImageNameDict setObject:bgColor forKey:imageName];
    }
    
    return bgColor;
}

// for IOS >= 8 devices
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions = [[NSMutableArray alloc] init];
    
    MXRoom* room = [self.dataSource getRoomAtIndexPath:indexPath];
    
    if (room)
    {
        NSString* title = @"      ";
        
        
        // pushes settings
        BOOL isMuted = ![self.dataSource isRoomNotifiedAtIndexPath:indexPath];
        
        UITableViewRowAction *muteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self muteRoomNotifications:!isMuted atIndexPath:indexPath];
            
        }];
        
        muteAction.backgroundColor = [self getBackgroundColor:isMuted ? @"unmute_icon" : @"mute_icon"];
        [actions insertObject:muteAction atIndex:0];
        
        // favorites management
        NSDictionary* tagsDict = [[NSDictionary alloc] init];
        
        // sanity cg
        if (room.accountData.tags)
        {
            tagsDict = [NSDictionary dictionaryWithDictionary:room.accountData.tags];
        }
    
        // get the room tag
        // use only the first one
        NSArray<MXRoomTag*>* tags = tagsDict.allValues;
        MXRoomTag* currentTag = nil;
        
        if (tags.count)
        {
            currentTag = [tags objectAtIndex:0];
        }
        
        if (!currentTag || ![kMXRoomTagFavourite isEqualToString:currentTag.name])
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateRoomTagAtIndexPath:indexPath to:kMXRoomTagFavourite];
            }];
            
            action.backgroundColor = [self getBackgroundColor:@"favorite_icon"];
            [actions insertObject:action atIndex:0];
        }
        
        if (currentTag && ([kMXRoomTagFavourite isEqualToString:currentTag.name] || [kMXRoomTagLowPriority isEqualToString:currentTag.name]))
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Std" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateRoomTagAtIndexPath:indexPath to:nil];
            }];
            
            action.backgroundColor = [self getBackgroundColor:nil];
            [actions insertObject:action atIndex:0];
        }
        
        if (!currentTag || ![kMXRoomTagLowPriority isEqualToString:currentTag.name])
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateRoomTagAtIndexPath:indexPath to:kMXRoomTagLowPriority];
            }];
            
            action.backgroundColor = [self getBackgroundColor:@"low_priority_icon"];
            [actions insertObject:action atIndex:0];
        }
        
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:title  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            [self leaveRecentsAtIndexPath:indexPath];
        }];
        leaveAction.backgroundColor = [self getBackgroundColor:@"remove_icon"];
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}

- (void)leaveRecentsAtIndexPath:(NSIndexPath *)indexPath
{
    [self.dataSource leaveRoomAtIndexPath:indexPath];
    [self.recentsTableView setEditing:NO];
}

- (void)updateRoomTagAtIndexPath:(NSIndexPath *)indexPath to:(NSString*)tag
{
    [self.dataSource updateRoomTagAtIndexPath:indexPath to:tag];
    [self.recentsTableView setEditing:NO];
}

- (void)muteRoomNotifications:(BOOL)mute atIndexPath:(NSIndexPath*)path
{
    [self.dataSource muteRoomNotifications:mute atIndexPath:path];
    [self.recentsTableView setEditing:NO];
}




#pragma mark - Override UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Prepare table refresh on new search session
    shouldScrollToTopOnRefresh = YES;
    
    [super searchBar:searchBar textDidChange:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Prepare table refresh on end of search
    shouldScrollToTopOnRefresh = YES;
    
    [super searchBarCancelButtonClicked: searchBar];
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [(RecentsDataSource*)self.dataSource heightForHeaderInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [self.recentsTableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[InviteRecentTableViewCell class]])
    {
        // hide the selection
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else
    {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

#pragma mark - Actions

- (IBAction)search:(id)sender
{
    [self performSegueWithIdentifier:@"presentSearch" sender:self];
}

#pragma mark - recents drag & drop management
- (IBAction) onRecentsLongPress:(id)sender
{
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    CGPoint location = [longPress locationInView:self.recentsTableView];
    NSIndexPath *indexPath = [self.recentsTableView indexPathForRowAtPoint:location];
    
    switch (state)
    {
        // step 1 : display the selected cell
        case UIGestureRecognizerStateBegan:
        {
            if (indexPath)
            {
                UITableViewCell *cell = [self.recentsTableView cellForRowAtIndexPath:indexPath];
                
                // snapshot the cell
                UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
                [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                cellSnapshot = [[UIImageView alloc] initWithImage:image];
                
                // display the selected cell over the tableview
                CGPoint center = cell.center;
                center.y = location.y;
                cellSnapshot.center = center;
                cellSnapshot.alpha = 0.5f;
                [self.recentsTableView addSubview:cellSnapshot];
            }
            break;
        }
        
        // step 2 : the cell must follow the finger
        case UIGestureRecognizerStateChanged:
        {
            CGPoint center = cellSnapshot.center;
            CGFloat halfHeight = cellSnapshot.frame.size.height / 2.0f;
            CGFloat cellTop = location.y - halfHeight;
            CGFloat cellBottom = location.y + halfHeight;
            
            CGPoint contentOffset =  self.recentsTableView.contentOffset;
            CGFloat height = MIN(self.recentsTableView.frame.size.height, self.recentsTableView.contentSize.height);
            CGFloat bottomOffset = contentOffset.y + height;
            
            // check if the moving cell is trying to move under the tableview
            if (cellBottom > self.recentsTableView.contentSize.height)
            {
                // force the cell to stay at the tableview bottom
                location.y = self.recentsTableView.contentSize.height - halfHeight;
            }
            // check if the cell is moving over the displayed tableview bottom
            else if (cellBottom > bottomOffset)
            {
                CGFloat diff = cellBottom - bottomOffset;
                
                // moving down the cell
                location.y -= diff;
                // scroll up the tableview
                contentOffset.y += diff;
            }
            // the moving is tryin to move over the tableview topmost
            else if (cellTop < 0)
            {
                // force to stay in the topmost
                contentOffset.y  = 0;
                location.y = contentOffset.y + halfHeight;
            }
            // the moving cell is displayed over the current scroll top
            else if (cellTop < contentOffset.y)
            {
                CGFloat diff = contentOffset.y - cellTop;
             
                // move up the cell and the table up
                location.y -= diff;
                contentOffset.y -= diff;
            }
            
            // move the cell to follow the user finger
            center.y = location.y;
            cellSnapshot.center = center;
            
            // scroll the tableview if it is required
            if (contentOffset.y != self.recentsTableView.contentOffset.y)
            {
                [self.recentsTableView setContentOffset:contentOffset animated:NO];
            }
            
            break;
        }

        // step 3 : remove the view
        // and insert when it is possible.
        case UIGestureRecognizerStateEnded:
        {
            [cellSnapshot removeFromSuperview];
            break;
        }
    }
}


@end
