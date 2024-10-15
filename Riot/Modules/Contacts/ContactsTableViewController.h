/*
Copyright 2024 New Vector Ltd.
Copyright 2017 OpenMarket Ltd
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "ContactsDataSource.h"
#import "ContactTableViewCell.h"

@class ContactsTableViewController;
@class AnalyticsScreenTracker;

/**
 `ContactsTableViewController` delegate.
 */
@protocol ContactsTableViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a contact.
 
 @param contactsTableViewController the `ContactsTableViewController` instance.
 @param contact the selected contact.
 */
- (void)contactsTableViewController:(ContactsTableViewController *)contactsTableViewController didSelectContact:(MXKContact*)contact;

@end

/**
 'ContactsTableViewController' instance is used to display/filter a list of contacts.
 See 'ContactsTableViewController-inherited' object for example of use.
 */
@interface ContactsTableViewController : MXKViewController <UITableViewDelegate, MXKDataSourceDelegate>
{
@protected
    ContactsDataSource *contactsDataSource;
}

/**
 Returns the `UINib` object initialized for a `ContactsTableViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `ContactsTableViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `ContactsTableViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)contactsTableViewController;

/**
 The contacts table view.
 */
@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;

/**
 When true, the footer that allows the user to enable local contacts sync will
 never be shown. When false, the footer will shown when the user hasn't enabled
 contact sync.
 */
@property (nonatomic) BOOL disableFindYourContactsFooter;

/**
 Indicates when there's an active search. This is used to determine when the contacts
 access footer should be hidden in order to list the results from the server.
 */
@property (nonatomic) BOOL contactsAreFilteredWithSearch;

/**
 If YES, the table view will scroll at the top on the next data source refresh.
 It comes back to NO after each refresh.
 */
@property (nonatomic) BOOL shouldScrollToTopOnRefresh;

/**
 Callback used to take into account the change of the user interface theme.
 */
- (void)userInterfaceThemeDidChange;

/**
 Refresh the cell selection in the table.
 
 This must be done accordingly to the currently selected contact in the master tabbar of the application.
 
 @param forceVisible if YES and if the corresponding cell is not visible, scroll the table view to make it visible.
 */
- (void)refreshCurrentSelectedCell:(BOOL)forceVisible;

/**
 Display the contacts described in the provided data source.
 
 The provided data source will replace the current data source if any. The caller
 should dispose properly this data source if it is not used anymore.
 
 @param listDataSource the data source providing the contacts list.
 */
- (void)displayList:(ContactsDataSource*)listDataSource;

/**
 Refresh the contacts table display.
 */
- (void)refreshContactsTable;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<ContactsTableViewControllerDelegate> contactsTableViewControllerDelegate;

/**
 The screen timer used for analytics if they've been enabled. The default value is nil.
 */
@property (nonatomic) AnalyticsScreenTracker *screenTracker;

@end

