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
 Filter the contacts list, by keeping only the contacts who have the search pattern
 as prefix in their display name, their matrix identifiers and/or their contact methods (emails, phones).
 
 @param searchText the search pattern (nil to reset filtering).
 @param forceRefresh tell whether the previous filtered contacts list must be reinitialized before searching (use NO by default).
 */
- (void)searchWithPattern:(NSString *)searchText forceRefresh:(BOOL)forceRefresh;

/**
 Refresh the contacts table display.
 */
- (void)refreshTableView;

@end

