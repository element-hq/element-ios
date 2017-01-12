/*
 Copyright 2017 OpenMarket Ltd
 
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

#import <MatrixKit/MatrixKit.h>

#import "ContactTableViewCell.h"
#import "VectorDesignValues.h"

@class ContactsTableViewController;

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
@interface ContactsTableViewController : MXKViewController <UITableViewDelegate, UITableViewDataSource>
{
@protected
    // Section indexes
    NSInteger searchInputSection;
    NSInteger filteredLocalContactsSection;
    NSInteger filteredMatrixContactsSection;
    
    // The contact used to describe the current user.
    MXKContact *userContact;
    
    // The dictionary of the ignored local contacts, the keys are their email. Empty by default.
    NSMutableDictionary<NSString*, MXKContact*> *ignoredContactsByEmail;
    
    //The dictionary of the ignored matrix contacts, the keys are their matrix identifier. Empty by default.
    NSMutableDictionary<NSString*, MXKContact*> *ignoredContactsByMatrixId;
    
    // Search results
    NSString *currentSearchText;
    NSMutableArray<MXKContact*> *filteredLocalContacts;
    NSMutableArray<MXKContact*> *filteredMatrixContacts;
    
    MXKAlert *currentAlert;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

/**
 Tell whether the matrix id should be added by default in the matrix contact display name (NO by default).
 If NO, the matrix id is added only to disambiguate the contact display names which appear several times.
 */
@property (nonatomic) BOOL forceMatrixIdInDisplayName;

/**
 Filter the contacts list, by keeping only the contacts who have the search pattern
 as prefix in their display name, their matrix identifiers and/or their contact methods (emails, phones).
 
 @param searchText the search pattern (nil to reset filtering).
 @param forceReset tell whether the search request must be applied by ignoring the previous search result if any (use NO by default).
 */
- (void)searchWithPattern:(NSString *)searchText forceReset:(BOOL)forceReset;

/**
 Refresh the contacts table display.
 */
- (void)refreshTableView;

/**
 The delegate for the view controller.
 */
@property (nonatomic) id<ContactsTableViewControllerDelegate> contactsTableViewControllerDelegate;

@end

