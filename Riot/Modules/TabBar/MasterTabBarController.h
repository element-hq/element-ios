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

#import <MatrixKit/MatrixKit.h>

#import "AuthenticationViewController.h"

#import "HomeViewController.h"
#import "FavouritesViewController.h"
#import "PeopleViewController.h"
#import "RoomsViewController.h"
#import "GroupsViewController.h"

#import "RoomViewController.h"
#import "ContactDetailsViewController.h"
#import "GroupDetailsViewController.h"

#define TABBAR_HOME_INDEX         0
#define TABBAR_FAVOURITES_INDEX   1
#define TABBAR_PEOPLE_INDEX       2
#define TABBAR_ROOMS_INDEX        3
#define TABBAR_GROUPS_INDEX       4
#define TABBAR_COUNT              5

@interface MasterTabBarController : UITabBarController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarButtonIem;

// Associated matrix sessions (empty by default).
@property (nonatomic, readonly) NSArray *mxSessions;

// Add a matrix session. This session is propagated to all view controllers handled by the tab bar controller.
- (void)addMatrixSession:(MXSession*)mxSession;
// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;

/**
 Display the authentication screen.
 */
- (void)showAuthenticationScreen;

/**
 Display the authentication screen in order to pursue a registration process by using a predefined set
 of parameters.
 
 If the provided registration parameters are not supported, we switch back to the default login screen.
 
 @param parameters the set of parameters.
 */
- (void)showAuthenticationScreenWithRegistrationParameters:(NSDictionary*)parameters;

/**
 Open the room with the provided identifier in a specific matrix session.
 
 @param roomId the room identifier.
 @param eventId if not nil, the room will be opened on this event.
 @param mxSession the matrix session in which the room should be available.
 */
- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)mxSession;

/**
 Open the RoomViewController to display the preview of a room that is unknown for the user.
 
 This room can come from an email invitation link or a simple link to a room.
 
 @param roomPreviewData the data for the room preview.
 */
- (void)showRoomPreview:(RoomPreviewData*)roomPreviewData;

/**
 Open a ContactDetailsViewController to display the information of the provided contact.
 */
- (void)selectContact:(MXKContact*)contact;

/**
 Open a GroupDetailsViewController to display the information of the provided group.
 
 @param group
 @param mxSession the matrix session in which the group should be available.
 */
- (void)selectGroup:(MXGroup*)group inMatrixSession:(MXSession*)matrixSession;

/**
 Release the current selected item (if any).
 */
- (void)releaseSelectedItem;

/**
 Dismiss the unified search screen (if any).
 */
- (void)dismissUnifiedSearch:(BOOL)animated completion:(void (^)(void))completion;

/**
 The current number of rooms with missed notifications, including the invites.
 */
- (NSUInteger)missedDiscussionsCount;

/**
 The current number of rooms with unread highlighted messages.
 */
- (NSUInteger)missedHighlightDiscussionsCount;

/**
 Refresh the missed conversations badges on tab bar icon
 */
- (void)refreshTabBarBadges;


// Reference to the current auth VC. It is not nil only when the auth screen is displayed.
@property (nonatomic, readonly) AuthenticationViewController *authViewController;

@property (nonatomic, readonly) HomeViewController *homeViewController;
@property (nonatomic, readonly) FavouritesViewController *favouritesViewController;
@property (nonatomic, readonly) PeopleViewController *peopleViewController;
@property (nonatomic, readonly) RoomsViewController *roomsViewController;
@property (nonatomic, readonly) GroupsViewController *groupsViewController;

// References on the currently selected room and its view controller
@property (nonatomic, readonly) RoomViewController *currentRoomViewController;
@property (nonatomic, readonly) NSString  *selectedRoomId;
@property (nonatomic, readonly) NSString  *selectedEventId;
@property (nonatomic, readonly) MXSession *selectedRoomSession;
@property (nonatomic, readonly) MXKRoomDataSource *selectedRoomDataSource;
@property (nonatomic, readonly) RoomPreviewData *selectedRoomPreviewData;

// References on the currently selected contact and its view controller
@property (nonatomic, readonly) ContactDetailsViewController *currentContactDetailViewController;
@property (nonatomic, readonly) MXKContact *selectedContact;

// References on the currently selected group and its view controller
@property (nonatomic, readonly) GroupDetailsViewController *currentGroupDetailViewController;
@property (nonatomic, readonly) MXGroup *selectedGroup;
@property (nonatomic, readonly) MXSession *selectedGroupSession;

@end

