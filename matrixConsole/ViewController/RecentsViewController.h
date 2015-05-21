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

@interface RecentsViewController : MXKRecentListViewController <MXKRecentListViewControllerDelegate, UISearchBarDelegate>

/**
 Open the room with the provided identifier in a specific matrix session.
 
 @param roomId the room identifier.
 @param mxSession the matrix session in which the room should be available.
 */
- (void)selectRoomWithId:(NSString*)roomId inMatrixSession:(MXSession*)mxSession;

/**
 Close the current selected room (if any)
 */
- (void)closeSelectedRoom;

@end

