//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
        MockUserSuggestionScreenState.self,
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
        MockVoiceBroadcastPlaybackScreenState.self
    ]
}
