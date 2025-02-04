// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#ifndef SplitViewMasterViewControllerProtocol_h
#define SplitViewMasterViewControllerProtocol_h

@class RoomNavigationParameters;
@class RoomPreviewNavigationParameters;
@class ScreenPresentationParameters;
@class OnboardingCoordinatorBridgePresenter;

@protocol SplitViewMasterTabBarViewControllerProtocol <NSObject>

/// Refresh the missed conversations badges on tab bar icon
- (void)refreshTabBarBadges;

/// Emulated `UITabBarViewController.selectedViewController` property
@property (nonatomic, readonly, nullable) UIViewController  *selectedViewController;

/// Emulated `UITabBarViewController.tabBar` property
@property (nonatomic, readonly, nullable) UITabBar  *tabBar;

@end

/// `SplitViewMasterViewControllerProtocol` describe the methods and properties needed by
@protocol SplitViewMasterViewControllerProtocol <SplitViewMasterTabBarViewControllerProtocol>

/// Display the default onboarding flow.
- (void)showOnboardingFlow;

/// Display the onboarding flow configured to log back into a soft logout session.
///
/// @param softLogoutCredentials the credentials of the soft logout session.
- (void)showSoftLogoutOnboardingFlowWithCredentials:(MXCredentials*)softLogoutCredentials;

/// Open the room with the provided identifier in a specific matrix session.
///
/// @param parameters the presentation parameters that contains room information plus display information.
/// @param completion the block to execute at the end of the operation.
- (void)selectRoomWithParameters:(RoomNavigationParameters*)parameters completion:(void (^)(void))completion;

/// Open the RoomViewController to display the preview of a room that is unknown for the user.
/// This room can come from an email invitation link or a simple link to a room.
///
/// @param parameters the presentation parameters that contains room preview information plus display information.
/// @param completion the block to execute at the end of the operation.
- (void)selectRoomPreviewWithParameters:(RoomPreviewNavigationParameters*)parameters completion:(void (^)(void))completion;

/// Open a ContactDetailsViewController to display the information of the provided contact.
///
/// @param contact contact to be displayed
- (void)selectContact:(MXKContact*)contact;

/// Open a ContactDetailsViewController to display the information of the provided contact according to the presentation parameters.
///
/// @param contact contact to be displayed
/// @param presentationParameters the presentation parameters that contains room preview information plus display information.
- (void)selectContact:(MXKContact*)contact withPresentationParameters:(ScreenPresentationParameters*)presentationParameters;

/// Release the current selected item (if any).
- (void)releaseSelectedItem;

/// The current number of rooms with missed notifications, including the invites.
- (NSUInteger)missedDiscussionsCount;

/// The current number of rooms with unread highlighted messages.
- (NSUInteger)missedHighlightDiscussionsCount;

/// Verify the current device if needed.
///
/// @param session the matrix session.
- (void)presentVerifyCurrentSessionAlertIfNeededWithSession:(MXSession*)session;

/// Verify others device if needed.
///
/// @param session the matrix session.
- (void)presentReviewUnverifiedSessionsAlertIfNeededWithSession:(MXSession*)session;

/// Reference to the current onboarding flow. It is always nil unless the flow is being presented.
@property (nonatomic, readonly) OnboardingCoordinatorBridgePresenter *onboardingCoordinatorBridgePresenter;

/// Reference on the currently selected room
@property (nonatomic, readonly) NSString  *selectedRoomId;
/// Reference on the currently selected event
@property (nonatomic, readonly) NSString  *selectedEventId;
/// Reference on the currently selected room session
@property (nonatomic, readonly) MXSession *selectedRoomSession;
/// Reference on the currently selected room preview data
@property (nonatomic, readonly) RoomPreviewData *selectedRoomPreviewData;

/// Reference on the currently selected contact
@property (nonatomic, readonly) MXKContact *selectedContact;

/// `true` while the onboarding flow is displayed
@property (nonatomic, readonly) BOOL isOnboardingInProgress;

@end

#endif /* SplitViewMasterViewControllerProtocol_h */
