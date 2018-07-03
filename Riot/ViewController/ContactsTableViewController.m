/*
 Copyright 2017 OpenMarket Ltd
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

#import "ContactsTableViewController.h"

#import "UIViewController+RiotSearch.h"

#import "AppDelegate.h"

#define CONTACTS_TABLEVC_LOCALCONTACTS_BITWISE 0x01
#define CONTACTS_TABLEVC_USERDIRECTORY_BITWISE 0x02

#define CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT 30.0
#define CONTACTS_TABLEVC_LOCALCONTACTS_SECTION_HEADER_HEIGHT 65.0

@interface ContactsTableViewController ()
{
    /**
     Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
     */
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    /**
     Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
     */
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

@end

@implementation ContactsTableViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([ContactsTableViewController class])
                          bundle:[NSBundle bundleForClass:[ContactsTableViewController class]]];
}

+ (instancetype)contactsTableViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([ContactsTableViewController class])
                                          bundle:[NSBundle bundleForClass:[ContactsTableViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    _screenName = @"ContactsTable";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Check whether the view controller has been pushed via storyboard
    if (!self.contactsTableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // Finalize table view configuration
    self.contactsTableView.delegate = self;
    self.contactsTableView.dataSource = contactsDataSource; // Note: dataSource may be nil here
    
    [self.contactsTableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:ContactTableViewCell.defaultReuseIdentifier];
    
    // Hide line separators of empty cells
    self.contactsTableView.tableFooterView = [[UIView alloc] init];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    // Check the table view style to select its bg color.
    self.contactsTableView.backgroundColor = ((self.contactsTableView.style == UITableViewStylePlain) ? kRiotPrimaryBgColor : kRiotSecondaryBgColor);
    self.view.backgroundColor = self.contactsTableView.backgroundColor;
    
    if (self.contactsTableView.dataSource)
    {
        [self refreshContactsTable];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    [super destroy];
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:_screenName];

    // Check whether the access to the local contacts has not been already asked.
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        // Allow by default the local contacts sync in order to discover matrix users.
        // This setting change will trigger the loading of the local contacts, which will automatically
        // ask user permission to access their local contacts.
        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
    }

    // Observe kAppDelegateDidTapStatusBarNotification.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.contactsTableView setContentOffset:CGPointMake(-self.contactsTableView.mxk_adjustedContentInset.left, -self.contactsTableView.mxk_adjustedContentInset.top) animated:YES];
        
    }];
    
    [self refreshContactsTable];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
}

#pragma mark -

- (void)displayList:(ContactsDataSource*)listDataSource
{
    // Cancel registration on existing dataSource if any
    if (contactsDataSource)
    {
        contactsDataSource.delegate = nil;
    }
    
    contactsDataSource = listDataSource;
    contactsDataSource.delegate = self;
    
    if (self.contactsTableView)
    {
        // Set up table data source
        self.contactsTableView.dataSource = contactsDataSource;
    }
}

- (void)refreshContactsTable
{
    [self.contactsTableView reloadData];
    
    if (_shouldScrollToTopOnRefresh)
    {
        [self scrollToTop:NO];
        _shouldScrollToTopOnRefresh = NO;
    }
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side on screen,
    // the selected room (if any) is updated and kept visible.
    if (self.splitViewController && !self.splitViewController.isCollapsed)
    {
        [self refreshCurrentSelectedCell:YES];
    }
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    MasterTabBarController *masterTabBarController = [AppDelegate theDelegate].masterTabBarController;
    if (masterTabBarController.currentContactDetailViewController)
    {
        // Look for the rank of this selected contact in displayed recents
        currentSelectedCellIndexPath = [contactsDataSource cellIndexPathWithContact:masterTabBarController.selectedContact];
    }
    
    if (currentSelectedCellIndexPath)
    {
        // Select the right row
        [self.contactsTableView selectRowAtIndexPath:currentSelectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        if (forceVisible)
        {
            // Scroll table view to make the selected row appear at second position
            NSInteger topCellIndexPathRow = currentSelectedCellIndexPath.row ? currentSelectedCellIndexPath.row - 1: currentSelectedCellIndexPath.row;
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:currentSelectedCellIndexPath.section];
            [self.contactsTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
    else
    {
        NSIndexPath *indexPath = [self.contactsTableView indexPathForSelectedRow];
        if (indexPath)
        {
            [self.contactsTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:MXKContact.class])
    {
        return ContactTableViewCell.class;
    }
    
    return nil;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:MXKContact.class])
    {
        return [ContactTableViewCell defaultReuseIdentifier];
    }
    
    return nil;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    [self refreshContactsTable];
}

#pragma mark - Internal methods

- (void)scrollToTop:(BOOL)animated
{
    // Scroll to the top
    [self.contactsTableView setContentOffset:CGPointMake(-self.contactsTableView.mxk_adjustedContentInset.left, -self.contactsTableView.mxk_adjustedContentInset.top) animated:animated];
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = kRiotPrimaryBgColor;
    
    // Update the selected background view
    if (kRiotSelectedBgColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = kRiotSelectedBgColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [contactsDataSource heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [contactsDataSource viewForHeaderInSection:section withFrame:[tableView rectForHeaderInSection:section]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([contactsDataSource contactAtIndexPath:indexPath])
    {
        // Return the default height of the contact cell
        return 74.0;
    }
    
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.contactsTableViewControllerDelegate)
    {
        MXKContact *mxkContact = [contactsDataSource contactAtIndexPath:indexPath];
        
        if (mxkContact)
        {
            [self.contactsTableViewControllerDelegate contactsTableViewController:self didSelectContact:mxkContact];
        
            // Keep selected the cell by default.
            return;
        }
    }
    // Else do nothing by default - `ContactsTableViewController-inherited` instance must override this method.
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchBar delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [contactsDataSource searchWithPattern:searchText forceReset:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed.
    
    if (self.contactsTableViewControllerDelegate)
    {
        // Check whether the current search input is a valid email or a Matrix user ID
        MXKContact* filedContact = [contactsDataSource searchInputContact];
        if (filedContact)
        {
            // Select the contact related to the search input, rather than having to hit +
            [self.contactsTableViewControllerDelegate contactsTableViewController:self didSelectContact:filedContact];
        }
    }
    
    // Dismiss keyboard
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    
    // Reset filtering
    [contactsDataSource searchWithPattern:nil forceReset:NO];
    
    // Leave search
    [searchBar resignFirstResponder];
    
    [self withdrawViewControllerAnimated:YES completion:nil];
}

@end
