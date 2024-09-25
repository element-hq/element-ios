/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 The state of the users search from the homeserver user directory.
 */
typedef enum : NSUInteger
{
    ContactsDataSourceUserDirectoryStateLoading,
    ContactsDataSourceUserDirectoryStateLoadedButLimited,
    ContactsDataSourceUserDirectoryStateLoaded,
    // The search is based on local known matrix contacts
    ContactsDataSourceUserDirectoryStateOfflineLoading,
    ContactsDataSourceUserDirectoryStateOfflineLoaded
} ContactsDataSourceUserDirectoryState;


/**
 'ContactsDataSource' is a base class to handle contacts in Riot.
 */
@interface ContactsDataSource : MXKDataSource <UITableViewDataSource, UIGestureRecognizerDelegate>
{
@protected
    // Section indexes
    NSInteger searchInputSection;
    NSInteger filteredLocalContactsSection;
    NSInteger filteredMatrixContactsSection;
    
    // Tell whether the non-matrix-enabled contacts must be hidden or not. NO by default.
    BOOL hideNonMatrixEnabledContacts;
    
    // Search results
    NSString *currentSearchText;
    NSMutableArray<MXKContact*> *filteredLocalContacts;
    NSMutableArray<MXKContact*> *filteredMatrixContacts;
}

/**
 Whether the data source should include local contacts in the table view. The default
 value is set at initialisation to match the `MXKAppSettings` value for `syncLocalContacts`.
 Note: After updating this property, the table view's data will need to be reloaded for it to have
 any effect.
 */
@property (nonatomic) BOOL showLocalContacts;

/**
 Get the contact at the given index path.
 
 @param indexPath the index of the cell
 @return the contact
 */
-(MXKContact *)contactAtIndexPath:(NSIndexPath*)indexPath;

/**
 Get the index path of the cell related to the provided contact.
 
 @param contact the contact.
 @return indexPath the index of the cell (nil if not found or if the related section is shrinked).
 */
- (NSIndexPath*)cellIndexPathWithContact:(MXKContact*)contact;

/**
 Get the height of the section header view.
 
 @param section the section  index
 @return the header height.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section;

/**
 Get the attributed string for the header title of the specified section.
 
 @param section the section  index.
 @return the section title.
 */
- (NSAttributedString *)attributedStringForHeaderTitleInSection:(NSInteger)section;

/**
 Get the section header view.
 
 @param section the section  index
 @param frame the drawing area for the header of the specified section.
 @param tableView the table view
 @return the section header.
 */
- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView *)tableView;

/**
 Get the sticky header view for the specified section.
 
 @param section the section  index
 @param frame the drawing area for the header of the specified section.
 @param tableView the table view
 @return the sticky header view.
 */
- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView *)tableView;

/**
 Refresh the contacts data source and notify its delegate.
 */
- (void)forceRefresh;

#pragma mark - Configuration
/**
 Tell whether the sections are shrinkable. NO by default.
 */
@property (nonatomic) BOOL areSectionsShrinkable;

/**
 Tell whether the matrix id should be added by default in the matrix contact display name (NO by default).
 If NO, the matrix id is added only to disambiguate the contact display names which appear several times.
 */
@property (nonatomic) BOOL forceMatrixIdInDisplayName;

/**
 The type of standard accessory view the contact cells should use
 Default is UITableViewCellAccessoryNone.
 */
@property (nonatomic) UITableViewCellAccessoryType contactCellAccessoryType;

/**
 An image used to create a custom accessy view on the right side of the contact cells.
 If set, use custom view. ignore accessoryType
 */
@property (nonatomic) UIImage *contactCellAccessoryImage;

/**
 The dictionary of the ignored local contacts, the keys are their email. Empty by default.
 */
@property (nonatomic) NSMutableDictionary<NSString*, MXKContact*> *ignoredContactsByEmail;

/**
 The dictionary of the ignored matrix contacts, the keys are their matrix identifier. Empty by default.
 */
@property (nonatomic) NSMutableDictionary<NSString*, MXKContact*> *ignoredContactsByMatrixId;

/**
 Filter the contacts list, by keeping only the contacts who have the search pattern
 as prefix in their display name, their matrix identifiers and/or their contact methods (emails, phones).
 
 @param searchText the search pattern (nil to reset filtering).
 @param forceReset tell whether the search request must be applied by ignoring the previous search result if any (use NO by default).
 */
- (void)searchWithPattern:(NSString *)searchText forceReset:(BOOL)forceReset;

/**
 Tell whether the search input is displayed in the contacts list. So that the user can select it (NO by default).
 */
@property (nonatomic) BOOL displaySearchInputInContactsList;

/**
 The temporary contact built from the search input. This contact is not nil only when the search input is
 a valid email or a Matrix user ID.
 */
@property (nonatomic, readonly) MXKContact *searchInputContact;

/**
 The state of the users search from the homeserver user directory.
 */
@property (nonatomic, readonly) ContactsDataSourceUserDirectoryState userDirectoryState;

@end
