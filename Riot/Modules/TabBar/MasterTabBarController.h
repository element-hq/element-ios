/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2020 New Vector Ltd
 
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

#import "AuthenticationViewController.h"

#import "RoomPreviewData.h"
#import "HomeViewController.h"
#import "FavouritesViewController.h"
#import "PeopleViewController.h"
#import "RoomsViewController.h"
#import "GroupsViewController.h"

#define TABBAR_HOME_INDEX         0
#define TABBAR_FAVOURITES_INDEX   1
#define TABBAR_PEOPLE_INDEX       2
#define TABBAR_ROOMS_INDEX        3
#define TABBAR_GROUPS_INDEX       4
#define TABBAR_COUNT              5

typedef NS_ENUM(NSUInteger, MasterTabBarIndex) {
    MasterTabBarIndexHome = TABBAR_HOME_INDEX,
    MasterTabBarIndexFavourites = TABBAR_FAVOURITES_INDEX,
    MasterTabBarIndexPeople = TABBAR_PEOPLE_INDEX,
    MasterTabBarIndexRooms = TABBAR_ROOMS_INDEX,
    MasterTabBarIndexGroups = TABBAR_GROUPS_INDEX
};

@protocol MasterTabBarControllerDelegate;
@class RoomNavigationParameters;
@class RoomPreviewNavigationParameters;
@class ScreenPresentationParameters;
@class OnboardingCoordinatorBridgePresenter;

@interface MasterTabBarController : UITabBarController

// UITabBarController already have a `delegate` property
@property (weak, nonatomic) id<MasterTabBarControllerDelegate> masterTabBarDelegate;

// Associated matrix sessions (empty by default).
@property (nonatomic, readonly) NSArray<MXSession*> *mxSessions;

// Add a matrix session. This session is propagated to all view controllers handled by the tab bar controller.
- (void)addMatrixSession:(MXSession*)mxSession;
// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;

/**
 Display the default onboarding flow.
 */
- (void)showOnboardingFlow;

/**
 Display the onboarding flow configured to log back into a soft logout session.

 @param softLogoutCredentials the credentials of the soft logout session.
 */
- (void)showSoftLogoutOnboardingFlowWithCredentials:(MXCredentials*)softLogoutCredentials;

/// Open the room with the provided identifier in a specific matrix session.
/// @param parameters the presentation parameters that contains room information plus display information.
/// @param completion the block to execute at the end of the operation.
- (void)selectRoomWithParameters:(RoomNavigationParameters*)parameters completion:(void (^)(void))completion;

/// Open the RoomViewController to display the preview of a room that is unknown for the user.
/// This room can come from an email invitation link or a simple link to a room.
/// @param parameters the presentation parameters that contains room preview information plus display information.
/// @param completion the block to execute at the end of the operation.
- (void)selectRoomPreviewWithParameters:(RoomPreviewNavigationParameters*)parameters completion:(void (^)(void))completion;

/**
 Open a ContactDetailsViewController to display the information of the provided contact.
 */
- (void)selectContact:(MXKContact*)contact;

- (void)selectContact:(MXKContact*)contact withPresentationParameters:(ScreenPresentationParameters*)presentationParameters;

/**
 Open a GroupDetailsViewController to display the information of the provided group.
 
 @param group Selected community.
 @param matrixSession the matrix session in which the group should be available.
 */
- (void)selectGroup:(MXGroup*)group inMatrixSession:(MXSession*)matrixSession;

- (void)selectGroup:(MXGroup*)group inMatrixSession:(MXSession*)matrixSession presentationParameters:(ScreenPresentationParameters*)presentationParameters;

/**
 Release the current selected item (if any).
 */
- (void)releaseSelectedItem;

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

/**
 Verify the current device if needed.
 
  @param session the matrix session.
 */
- (void)presentVerifyCurrentSessionAlertIfNeededWithSession:(MXSession*)session;

/**
 Verify others device if needed.
 
 @param session the matrix session.
 */
- (void)presentReviewUnverifiedSessionsAlertIfNeededWithSession:(MXSession*)session;


/// Filter rooms for each tab data source with the given room parent id.
/// It should keep rooms having an ancestor with `roomParentId` as parent id.
/// @param roomParentId The room parent id used to filter rooms.
/// @param mxSession The matrix session in which the room filtering should be done.
- (void)filterRoomsWithParentId:(NSString*)roomParentId
                inMatrixSession:(MXSession*)mxSession;

// Reference to the current onboarding flow. It is always nil unless the flow is being presented.
@property (nonatomic, readonly) OnboardingCoordinatorBridgePresenter *onboardingCoordinatorBridgePresenter;

@property (nonatomic, readonly) HomeViewController *homeViewController;
@property (nonatomic, readonly) FavouritesViewController *favouritesViewController;
@property (nonatomic, readonly) PeopleViewController *peopleViewController;
@property (nonatomic, readonly) RoomsViewController *roomsViewController;
@property (nonatomic, readonly) GroupsViewController *groupsViewController;


// References on the currently selected room
@property (nonatomic, readonly) NSString  *selectedRoomId;
@property (nonatomic, readonly) NSString  *selectedEventId;
@property (nonatomic, readonly) MXSession *selectedRoomSession;
@property (nonatomic, readonly) RoomPreviewData *selectedRoomPreviewData;

// References on the currently selected contact
@property (nonatomic, readonly) MXKContact *selectedContact;

// References on the currently selected group
@property (nonatomic, readonly) MXGroup *selectedGroup;
@property (nonatomic, readonly) MXSession *selectedGroupSession;

// YES while the onboarding flow is displayed
@property (nonatomic, readonly) BOOL isOnboardingInProgress;

// Set tab bar item controllers
- (void)updateViewControllers:(NSArray<UIViewController*>*)viewControllers;

- (void)removeTabAt:(MasterTabBarIndex)index;

- (void)selectTabAtIndex:(MasterTabBarIndex)tabBarIndex;

@end


@protocol MasterTabBarControllerDelegate <NSObject>

- (void)masterTabBarControllerDidCompleteAuthentication:(MasterTabBarController *)masterTabBarController;
- (void)masterTabBarController:(MasterTabBarController*)masterTabBarController needsSideMenuIconWithNotification:(BOOL)displayNotification;
- (void)masterTabBarController:(MasterTabBarController *)masterTabBarController didSelectRoomWithParameters:(RoomNavigationParameters*)roomNavigationParameters completion:(void (^)(void))completion;
- (void)masterTabBarController:(MasterTabBarController *)masterTabBarController didSelectRoomPreviewWithParameters:(RoomPreviewNavigationParameters*)roomPreviewNavigationParameters completion:(void (^)(void))completion;
- (void)masterTabBarController:(MasterTabBarController *)masterTabBarController didSelectContact:(MXKContact*)contact withPresentationParameters:(ScreenPresentationParameters*)presentationParameters;
- (void)masterTabBarController:(MasterTabBarController *)masterTabBarController didSelectGroup:(MXGroup*)group inMatrixSession:(MXSession*)matrixSession presentationParameters:(ScreenPresentationParameters*)presentationParameters;

@end
