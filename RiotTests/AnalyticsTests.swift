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

import XCTest
@testable import Riot

class AnalyticsTests: XCTestCase {
    func testAnalyticsPromptNewUser() {
        // Given a fresh install of the app (with neither PostHog nor Matomo analytics having been set).
        RiotSettings.defaults.removeObject(forKey: RiotSettings.UserDefaultsKeys.enableAnalytics)
        RiotSettings.defaults.removeObject(forKey: RiotSettings.UserDefaultsKeys.matomoAnalytics)
        
        // When the user is prompted for analytics.
        let showPrompt = Analytics.shared.shouldShowAnalyticsPrompt
        let displayUpgradeMessage = Analytics.shared.promptShouldDisplayUpgradeMessage
        
        // Then the regular prompt should be shown.
        XCTAssertTrue(showPrompt, "A prompt should be shown for a new user.")
        XCTAssertFalse(displayUpgradeMessage, "The prompt should not ask about upgrading from Matomo.")
    }
    
    func testAnalyticsPromptUpgradeFromMatomo() {
        // Given an existing install of the app where the user previously accepted Matomo analytics
        RiotSettings.defaults.removeObject(forKey: RiotSettings.UserDefaultsKeys.enableAnalytics)
        RiotSettings.defaults.set(true, forKey: RiotSettings.UserDefaultsKeys.matomoAnalytics)
        
        // When the user is prompted for analytics
        let showPrompt = Analytics.shared.shouldShowAnalyticsPrompt
        let displayUpgradeMessage = Analytics.shared.promptShouldDisplayUpgradeMessage
        
        // Then an upgrade prompt should be shown.
        XCTAssertTrue(showPrompt, "A prompt should be shown to the user.")
        XCTAssertTrue(displayUpgradeMessage, "The prompt should ask about upgrading from Matomo.")
    }
    
    func testAnalyticsPromptUserDeclinedMatomo() {
        // Given an existing install of the app where the user previously declined Matomo analytics
        RiotSettings.defaults.removeObject(forKey: RiotSettings.UserDefaultsKeys.enableAnalytics)
        RiotSettings.defaults.set(false, forKey: RiotSettings.UserDefaultsKeys.matomoAnalytics)
        
        // When the user is prompted for analytics
        let showPrompt = Analytics.shared.shouldShowAnalyticsPrompt
        let displayUpgradeMessage = Analytics.shared.promptShouldDisplayUpgradeMessage
        
        // Then the regular prompt should be shown.
        XCTAssertTrue(showPrompt, "A prompt should be shown to the user.")
        XCTAssertFalse(displayUpgradeMessage, "The prompt should not ask about upgrading from Matomo.")
    }
    
    func testAnalyticsPromptUserAcceptedPostHog() {
        // Given an existing install of the app where the user previously accepted PostHog
        RiotSettings.defaults.set(true, forKey: RiotSettings.UserDefaultsKeys.enableAnalytics)
        
        // When the user is prompted for analytics
        let showPrompt = Analytics.shared.shouldShowAnalyticsPrompt
        
        // Then no prompt should be shown.
        XCTAssertFalse(showPrompt, "A prompt should not be shown any more.")
    }
}
