//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The static list of mocked screens in RiotSwiftUI
enum MockAppScreens {
    static let appScreens: [MockScreenState.Type] = [
        MockUserSessionNameScreenState.self,
        MockUserOtherSessionsScreenState.self,
        MockUserSessionsOverviewScreenState.self,
        MockUserSessionDetailsScreenState.self,
        MockUserSessionOverviewScreenState.self,
        MockLiveLocationLabPromotionScreenState.self,
        MockLiveLocationSharingViewerScreenState.self,
        MockAuthenticationLoginScreenState.self,
        MockAuthenticationReCaptchaScreenState.self,
        MockAuthenticationTermsScreenState.self,
        MockAuthenticationVerifyEmailScreenState.self,
        MockAuthenticationVerifyMsisdnScreenState.self,
        MockAuthenticationRegistrationScreenState.self,
        MockAuthenticationServerSelectionScreenState.self,
        MockAuthenticationForgotPasswordScreenState.self,
        MockAuthenticationChoosePasswordScreenState.self,
        MockAuthenticationSoftLogoutScreenState.self,
        MockAuthenticationQRLoginStartScreenState.self,
        MockAuthenticationQRLoginDisplayScreenState.self,
        MockAuthenticationQRLoginScanScreenState.self,
        MockAuthenticationQRLoginConfirmScreenState.self,
        MockAuthenticationQRLoginLoadingScreenState.self,
        MockAuthenticationQRLoginFailureScreenState.self,
        MockOnboardingCelebrationScreenState.self,
        MockOnboardingAvatarScreenState.self,
        MockOnboardingDisplayNameScreenState.self,
        MockOnboardingCongratulationsScreenState.self,
        MockOnboardingUseCaseSelectionScreenState.self,
        MockOnboardingSplashScreenScreenState.self,
        MockStaticLocationViewingScreenState.self,
        MockLocationSharingScreenState.self,
        MockAnalyticsPromptScreenState.self,
        MockCompletionSuggestionScreenState.self,
        MockPollEditFormScreenState.self,
        MockSpaceCreationEmailInvitesScreenState.self,
        MockSpaceSettingsScreenState.self,
        MockRoomAccessTypeChooserScreenState.self,
        MockRoomUpgradeScreenState.self,
        MockMatrixItemChooserScreenState.self,
        MockSpaceCreationMenuScreenState.self,
        MockSpaceCreationRoomsScreenState.self,
        MockSpaceCreationSettingsScreenState.self,
        MockSpaceCreationPostProcessScreenState.self,
        MockTimelinePollScreenState.self,
        MockChangePasswordScreenState.self,
        MockTemplateSimpleScreenScreenState.self,
        MockTemplateUserProfileScreenState.self,
        MockTemplateRoomListScreenState.self,
        MockTemplateRoomChatScreenState.self,
        MockSpaceSelectorScreenState.self,
        MockComposerScreenState.self,
        MockComposerCreateActionListScreenState.self,
        MockComposerLinkActionScreenState.self,
        MockVoiceBroadcastPlaybackScreenState.self,
        MockPollHistoryScreenState.self,
        MockPollHistoryDetailScreenState.self
    ]
}
