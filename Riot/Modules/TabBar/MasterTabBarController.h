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
#import "SplitViewMasterViewControllerProtocol.h"

#define TABBAR_HOME_INDEX         0
#define TABBAR_FAVOURITES_INDEX   1
#define TABBAR_PEOPLE_INDEX       2
#define TABBAR_ROOMS_INDEX        3
#define TABBAR_COUNT              4

typedef NS_ENUM(NSUInteger, MasterTabBarIndex) {
    MasterTabBarIndexHome = TABBAR_HOME_INDEX,
    MasterTabBarIndexFavourites = TABBAR_FAVOURITES_INDEX,
    MasterTabBarIndexPeople = TABBAR_PEOPLE_INDEX,
    MasterTabBarIndexRooms = TABBAR_ROOMS_INDEX
};

@protocol MasterTabBarControllerDelegate;
@class RoomNavigationParameters;
@class RoomPreviewNavigationParameters;
@class ScreenPresentationParameters;
@class OnboardingCoordinatorBridgePresenter;

@interface MasterTabBarController : UITabBarController<SplitViewMasterViewControllerProtocol>

// UITabBarController already have a `delegate` property
@property (weak, nonatomic) id<MasterTabBarControllerDelegate> masterTabBarDelegate;

// Associated matrix sessions (empty by default).
@property (nonatomic, readonly) NSArray<MXSession*> *mxSessions;

// Add a matrix session. This session is propagated to all view controllers handled by the tab bar controller.
- (void)addMatrixSession:(MXSession*)mxSession;
// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;

/// Filter rooms for each tab data source with the given room parent id.
/// It should keep rooms having an ancestor with `roomParentId` as parent id.
/// @param roomParentId The room parent id used to filter rooms.
/// @param mxSession The matrix session in which the room filtering should be done.
- (void)filterRoomsWithParentId:(NSString*)roomParentId
                inMatrixSession:(MXSession*)mxSession;

@property (nonatomic, readonly) HomeViewController *homeViewController;
@property (nonatomic, readonly) FavouritesViewController *favouritesViewController;
@property (nonatomic, readonly) PeopleViewController *peopleViewController;
@property (nonatomic, readonly) RoomsViewController *roomsViewController;

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

@end
