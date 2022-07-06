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

#import <Contacts/Contacts.h>
#import "ContactsTableViewController.h"
#import "SectionHeaderView.h"

#import "UIViewController+RiotSearch.h"

#import "GeneratedInterface-Swift.h"

#define CONTACTS_TABLEVC_LOCALCONTACTS_BITWISE 0x01
#define CONTACTS_TABLEVC_USERDIRECTORY_BITWISE 0x02

#define CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT 30.0
#define CONTACTS_TABLEVC_LOCALCONTACTS_SECTION_HEADER_HEIGHT 65.0

@interface ContactsTableViewController () <FindYourContactsFooterViewDelegate, ServiceTermsModalCoordinatorBridgePresenterDelegate>
{
    /**
     Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
     */
    __weak id kAppDelegateDidTapStatusBarNotificationObserver;
    
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    __weak id kThemeServiceDidChangeThemeNotificationObserver;
}

@property (nonatomic, strong) FindYourContactsFooterView *findYourContactsFooterView;

@property (nonatomic, strong) ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter;

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
    
    // By default, allow the find your contacts footer to be
    // shown when local contacts sync hasn't been enabled.
    self.disableFindYourContactsFooter = NO;
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
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

    [self.contactsTableView registerClass:SectionHeaderView.class
       forHeaderFooterViewReuseIdentifier:SectionHeaderView.defaultReuseIdentifier];
    
    // Hide line separators of empty cells
    self.contactsTableView.tableFooterView = [[UIView alloc] init];
    self.contactsAreFilteredWithSearch = NO;
    
    MXWeakify(self);
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];

    if (@available(iOS 15.0, *))
    {
        [[_contactsTableView.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor] setActive:YES];
    }
    else
    {
        [[_contactsTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor] setActive:YES];
    }
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    // Check the table view style to select its bg color.
    self.contactsTableView.backgroundColor = ((self.contactsTableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.contactsTableView.backgroundColor;
    self.contactsTableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    if (self.contactsTableView.dataSource)
    {
        [self refreshContactsTable];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    [super destroy];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    MXWeakify(self);

    // Observe kAppDelegateDidTapStatusBarNotification.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self.contactsTableView setContentOffset:CGPointMake(-self.contactsTableView.adjustedContentInset.left, -self.contactsTableView.adjustedContentInset.top) animated:YES];
        
    }];
    
    // Load the local contacts for display.
    [self refreshLocalContacts];
    [self refreshContactsTable];
    
    // Show the contacts access footer if necessary.
    [self updateFooterViewVisibility];
    [self.screenTracker trackScreen];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateFooterViewHeight];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }

    if (!self.searchBarHidden && self.extendedLayoutIncludesOpaqueBars)
    {
        //  if a search bar is visible, navigationBar height will be increased. Below code will force update layout on previous view controller.
        [self.navigationController.view setNeedsLayout]; // force update layout
        [self.navigationController.view layoutIfNeeded]; // to fix height of the navigation bar
    }
}

#pragma mark -

/**
 Creates a new `FindYourContactsFooterView` and caches it in
 the `findYourContactsFooterView` property before returning it for use.
 */
- (FindYourContactsFooterView*)makeFooterView
{
    FindYourContactsFooterView *footerView = [FindYourContactsFooterView instantiate];
    footerView.delegate = self;
    
    self.findYourContactsFooterView = footerView;
    
    return footerView;
}

/**
 Checks whether local contacts sync is ready to use or if there are any search results
 in the table, hiding the find your contacts footer if so. Otherwise the footer is shown
 so long as it hasn't been disabled.
 */
- (void)updateFooterViewVisibility
{
    if (!BuildSettings.allowLocalContactsAccess || self.disableFindYourContactsFooter)
    {
        self.contactsTableView.tableFooterView = [[UIView alloc] init];
        return;
    }
    
    // With contacts access granted, contact sync enabled and an identity server, the footer can be hidden.
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized
        && MXKAppSettings.standardAppSettings.syncLocalContacts
        && contactsDataSource.mxSession.identityService.areAllTermsAgreed)
    {
        self.contactsTableView.tableFooterView = [[UIView alloc] init];
        return;
    }
    
    // If the footer is to be shown, hide it when there's an active search.
    if (self.contactsAreFilteredWithSearch)
    {
        self.contactsTableView.tableFooterView = [[UIView alloc] init];
        return;
    }
    
    self.contactsTableView.tableFooterView = self.findYourContactsFooterView ?: [self makeFooterView];
    [self updateFooterViewHeight];
}

/**
 Updates the height of the find your contacts footer to fill all available space.
 */
- (void)updateFooterViewHeight
{
    if (self.findYourContactsFooterView && self.findYourContactsFooterView == self.contactsTableView.tableFooterView)
    {
        // Calculate the natural size of the footer
        CGSize fittingSize = CGSizeMake(self.view.frame.size.width, UILayoutFittingCompressedSize.height);
        CGSize footerSize = [self.findYourContactsFooterView systemLayoutSizeFittingSize:fittingSize];
        
        // Calculate the height available for the footer
        CGFloat availableHeight = self.contactsTableView.bounds.size.height - self.contactsTableView.adjustedContentInset.top - self.contactsTableView.adjustedContentInset.bottom;
        if (self.contactsTableView.tableHeaderView)
        {
            availableHeight -= self.contactsTableView.tableHeaderView.frame.size.height;
        }
        
        // Fill all available height unless the footer is larger, in which case use its natural height
        CGFloat finalHeight = availableHeight > footerSize.height ? availableHeight : footerSize.height;
        self.findYourContactsFooterView.frame = CGRectMake(self.findYourContactsFooterView.frame.origin.x,
                                                           self.findYourContactsFooterView.frame.origin.y,
                                                           self.findYourContactsFooterView.frame.size.width,
                                                           finalHeight);
        
        // This assignment is technically redundant, but does prompt the table view to recalculate its content size
        self.contactsTableView.tableFooterView = self.findYourContactsFooterView;
    }
}

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

- (void)refreshLocalContacts
{
    if (!BuildSettings.allowLocalContactsAccess)
    {
        return;
    }
    
    if (MXKAppSettings.standardAppSettings.syncLocalContacts
        && contactsDataSource.mxSession.identityService.areAllTermsAgreed
        && [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized)
    {
        // Refresh the local contacts list.
        [[MXKContactManager sharedManager] refreshLocalContacts];
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
    if (masterTabBarController.selectedContact)
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

- (void)setContactsAreFilteredWithSearch:(BOOL)contactsAreFilteredWithSearch
{
    // Filter out redundant assignments.
    if (_contactsAreFilteredWithSearch != contactsAreFilteredWithSearch)
    {
        _contactsAreFilteredWithSearch = contactsAreFilteredWithSearch;
        [self updateFooterViewVisibility];
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
    [self.contactsTableView setContentOffset:CGPointMake(-self.contactsTableView.adjustedContentInset.left, -self.contactsTableView.adjustedContentInset.top) animated:animated];
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
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
    return [contactsDataSource viewForHeaderInSection:section
                                            withFrame:[tableView rectForHeaderInSection:section]
                                          inTableView:tableView];
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
    
    self.contactsAreFilteredWithSearch = searchText.length ? YES : NO;
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

#pragma mark - FindYourContactsFooterViewDelegate

- (void)contactsFooterViewDidRequestFindContacts:(FindYourContactsFooterView *)footerView
{
    // First check the identity if service terms have already been accepted
    if (self->contactsDataSource.mxSession.identityService.areAllTermsAgreed)
    {
        // If they have we only require local contacts access.
        [self checkAccessForContacts];
    }
    else
    {
        MXWeakify(self);
        
        // The preparation can take some time so indicate this to the user
        [self startActivityIndicator];
        footerView.isActionEnabled = NO;
        
        [self->contactsDataSource.mxSession prepareIdentityServiceForTermsWithDefault:RiotSettings.shared.identityServerUrlString
                                                                              success:^(MXSession *session, NSString *baseURL, NSString *accessToken) {
            MXStrongifyAndReturnIfNil(self);
            
            [self stopActivityIndicator];
            footerView.isActionEnabled = YES;
            
            // Present the terms of the identity server.
            [self presentIdentityServerTermsWithSession:session baseURL:baseURL andAccessToken:accessToken];
        } failure:^(NSError *error) {
            // The error was already logged before the block is called
            MXStrongifyAndReturnIfNil(self);
            
            [self stopActivityIndicator];
            footerView.isActionEnabled = YES;
            
            // Alert the user that something went wrong.
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:VectorL10n.findYourContactsIdentityServiceError
                                                                                     message:nil
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addAction:[UIAlertAction actionWithTitle:VectorL10n.ok
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil]];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }];
    }
}
    
 - (void)checkAccessForContacts
{
    MXWeakify(self);
    
    // Check for contacts access, showing a pop-up if necessary.
    [MXKTools checkAccessForContacts:VectorL10n.contactsAddressBookPermissionDeniedAlertTitle
             withManualChangeMessage:VectorL10n.contactsAddressBookPermissionDeniedAlertMessage
           showPopUpInViewController:self
                   completionHandler:^(BOOL granted) {
        
        MXStrongifyAndReturnIfNil(self);
        
        if (granted)
        {
            // When granted, local contacts can be shown.
            [self showLocalContacts];
        }
    }];
}

- (void)showLocalContacts
{
    // Enable local contacts sync and display.
    MXKAppSettings.standardAppSettings.syncLocalContacts = YES;
    self->contactsDataSource.showLocalContacts = YES;
    
    // Attempt to refresh the contacts manager.
    [self refreshLocalContacts];
    
    // Hide the find your contacts footer.
    [self updateFooterViewVisibility];
}

#pragma mark - Identity server service terms

- (void)presentIdentityServerTermsWithSession:(MXSession*)mxSession baseURL:(NSString*)baseURL andAccessToken:(NSString*)accessToken
{
    if (!mxSession || !baseURL || !accessToken || self.serviceTermsModalCoordinatorBridgePresenter.isPresenting)
    {
        return;
    }
    
    ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter = [[ServiceTermsModalCoordinatorBridgePresenter alloc] initWithSession:mxSession
                                                                                                                                                            baseUrl:baseURL
                                                                                                                                                        serviceType:MXServiceTypeIdentityService
                                                                                                                                                        accessToken:accessToken];
    
    serviceTermsModalCoordinatorBridgePresenter.delegate = self;
    
    [serviceTermsModalCoordinatorBridgePresenter presentFrom:self animated:YES];
    self.serviceTermsModalCoordinatorBridgePresenter = serviceTermsModalCoordinatorBridgePresenter;
}

#pragma mark ServiceTermsModalCoordinatorBridgePresenterDelegate

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self checkAccessForContacts];
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline:(ServiceTermsModalCoordinatorBridgePresenter *)coordinatorBridgePresenter session:(MXSession *)session
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidClose:(ServiceTermsModalCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

@end
