/*
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
#import "RecentsDataSource.h"

/**
 'PeopleViewController' instance is used to display/filter the direct rooms and a list of contacts.
 */
@interface PeopleViewController : ContactsTableViewController <MXKDataSourceDelegate>

/**
 Display the direct rooms from the provided data source.
 
 Note: The provided data source will replace the current data source if any. The caller
 should dispose properly this data source if it is not used anymore.
 
 @param directRoomsDataSource the data source providing the direct rooms list.
 */
- (void)displayDirectRooms:(RecentsDataSource*)directRoomsDataSource;

@end

