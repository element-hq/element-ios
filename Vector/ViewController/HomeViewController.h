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

#import <MatrixKit/MatrixKit.h>

@interface HomeViewController:MXKViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate, MXKRoomCreationViewDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *publicRoomsSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *publicRoomsSearchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *publicRoomsSearchBarTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomConstraint;

/**
 Add a matrix REST Client. It is used to make Matrix API requests and retrieve public rooms.
 */
- (void)addRestClient:(MXRestClient*)restClient;

/**
 Remove a matrix REST Client.
 */
- (void)removeRestClient:(MXRestClient*)restClient;

/**
 Enable the search in recents list according to the room display name (YES by default).
 Set NO this property to disable this option and hide the related bar button.
 */
@property (nonatomic) BOOL enableSearch;

@end

