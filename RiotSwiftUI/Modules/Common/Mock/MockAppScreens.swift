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
@available(iOS 14.0, *)
enum MockAppScreens {
    static let appScreens: [MockScreenState.Type] = [
        MockLiveLocationSharingViewerScreenState.self,
        MockAuthenticationRegistrationScreenState.self,
        MockAuthenticationServerSelectionScreenState.self,
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
        MockTemplateSimpleScreenScreenState.self,
        MockTemplateUserProfileScreenState.self,
        MockTemplateRoomListScreenState.self,
        MockTemplateRoomChatScreenState.self
    ]
}

