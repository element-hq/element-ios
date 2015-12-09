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
#import "RoomViewController.h"

#import "RecentTableViewCell.h"

#import "RageShakeManager.h"

#import "NSBundle+MatrixKit.h"

#import "RecentsDataSource.h"

#import "VectorDesignValues.h"

#import "SearchViewController.h"

@interface RecentsViewController ()
{
    // Recents refresh handling
    BOOL shouldScrollToTopOnRefresh;
    
    // Selected room description
    NSString  *selectedRoomId;
    MXSession *selectedRoomSession;
    
    // Keep reference on the current room view controller to release it correctly
    RoomViewController *currentRoomViewController;
    
    // Keep the selected cell index to handle correctly split view controller display in landscape mode
    NSIndexPath *currentSelectedCellIndexPath;
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
    
    // Initialisation
    currentSelectedCellIndexPath = nil;
    
    // Setup `MXKRecentListViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // The view controller handles itself the selected recent
    self.delegate = self;
    
    // Register here the customized cell view class used to render recents
    [self.recentsTableView registerNib:RecentTableViewCell.nib forCellReuseIdentifier:RecentTableViewCell.defaultReuseIdentifier];
}

- (void)dealloc
{
    [self closeSelectedRoom];
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
    
    selectedRoomId = nil;
    selectedRoomSession = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
    // Note: 'isCollapsed' property is available in UISplitViewController for iOS 8 and later.
    if (!self.splitViewController || ([self.splitViewController respondsToSelector:@selector(isCollapsed)] && self.splitViewController.isCollapsed))
    {
        // Release the current selected room (if any).
        [self closeSelectedRoom];
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

- (void)selectRoomWithId:(NSString*)roomId inMatrixSession:(MXSession*)matrixSession
{
    if (selectedRoomId && [selectedRoomId isEqualToString:roomId]
        && selectedRoomSession && selectedRoomSession == matrixSession)
    {
        // Nothing to do
        return;
    }
    
    selectedRoomId = roomId;
    selectedRoomSession = matrixSession;
    
    if (roomId && matrixSession)
    {
        [self performSegueWithIdentifier:@"showDetails" sender:self];
    }
    else
    {
        [self closeSelectedRoom];
    }
}

- (void)closeSelectedRoom
{
    selectedRoomId = nil;
    selectedRoomSession = nil;
    
    if (currentRoomViewController)
    {
        if (currentRoomViewController.roomDataSource)
        {
            // Let the manager release this room data source
            MXSession *mxSession = currentRoomViewController.roomDataSource.mxSession;
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];
            [roomDataSourceManager closeRoomDataSource:currentRoomViewController.roomDataSource forceClose:NO];
        }

        [currentRoomViewController destroy];
        currentRoomViewController = nil;
    }
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
    currentSelectedCellIndexPath = nil;
    if (currentRoomViewController)
    {
        // Restore the current selected room id, it is erased when view controller disappeared (see viewWillDisappear).
        if (!selectedRoomId)
        {
            selectedRoomId = currentRoomViewController.roomDataSource.roomId;
            selectedRoomSession = currentRoomViewController.mainSession;
        }
        
        // Look for the rank of this selected room in displayed recents
        currentSelectedCellIndexPath = [self.dataSource cellIndexPathWithRoomId:selectedRoomId andMatrixSession:selectedRoomSession];
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

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];
    
    if ([[segue identifier] isEqualToString:@"showDetails"])
    {
        UIViewController *controller;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]])
        {
            controller = [[segue destinationViewController] topViewController];
        }
        else
        {
            controller = [segue destinationViewController];
        }
        
        if ([controller isKindOfClass:[RoomViewController class]])
        {
            // Release existing Room view controller (if any)
            if (currentRoomViewController)
            {
                if (currentRoomViewController.roomDataSource)
                {
                    // Let the manager release this room data source
                    MXSession *mxSession = currentRoomViewController.roomDataSource.mxSession;
                    MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];
                    [roomDataSourceManager closeRoomDataSource:currentRoomViewController.roomDataSource forceClose:NO];
                }
                
                [currentRoomViewController destroy];
                currentRoomViewController = nil;
            }
            
            currentRoomViewController = (RoomViewController *)controller;
            
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:selectedRoomSession];
            MXKRoomDataSource *roomDataSource = [roomDataSourceManager roomDataSourceForRoom:selectedRoomId create:YES];
            [currentRoomViewController displayRoom:roomDataSource];
        }
        
        if (self.splitViewController)
        {
            // Refresh selected cell without scrolling the selected cell (We suppose it's visible here)
            [self refreshCurrentSelectedCell:NO];
            
            // IOS >= 8
            if ([self.splitViewController respondsToSelector:@selector(displayModeButtonItem)])
            {
                controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
            }
            
            //
            controller.navigationItem.leftItemsSupplementBackButton = YES;
        }
    }
    else if ([[segue identifier] isEqualToString:@"presentSearch"])
    {
        SearchViewController *searchViewController = (SearchViewController*)segue.destinationViewController;
        [searchViewController displayWithSession:self.dataSource.mxSession];
    }
    
    // Hide back button title
    self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{ 
    // Return the customized recent table view cell
    return RecentTableViewCell.class;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    // Return the customized recent table view cell identifier
    return RecentTableViewCell.defaultReuseIdentifier;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
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


#pragma mark - MXKRecentListViewControllerDelegate

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
{
    // Open the room
    [self selectRoomWithId:roomId inMatrixSession:matrixSession];
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

#pragma mark - Actions

- (IBAction)search:(id)sender
{
    [self performSegueWithIdentifier:@"presentSearch" sender:self];
}

@end
