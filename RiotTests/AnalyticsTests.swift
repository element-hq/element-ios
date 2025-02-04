// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
@testable import Element
import AnalyticsEvents

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
    
    func testAddingUserProperties() {
        // Given a client with no user properties set
        let client = PostHogAnalyticsClient()
        XCTAssertNil(client.pendingUserProperties, "No user properties should have been set yet.")
        
        // When updating the user properties
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: .PersonalMessaging, numFavouriteRooms: 4, numSpaces: 5, recoveryState: nil, verificationState: nil))
        
        // Then the properties should be cached
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection should match.")
        XCTAssertEqual(client.pendingUserProperties?.numFavouriteRooms, 4, "The number of favorite rooms should match.")
        XCTAssertEqual(client.pendingUserProperties?.numSpaces, 5, "The number of spaces should match.")
    }
    
    func testMergingUserProperties() {
        // Given a client with a cached use case user properties
        let client = PostHogAnalyticsClient()
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: .PersonalMessaging, numFavouriteRooms: nil, numSpaces: nil, recoveryState: nil, verificationState: nil))
        
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection should match.")
        XCTAssertNil(client.pendingUserProperties?.numFavouriteRooms, "The number of favorite rooms should not be set.")
        XCTAssertNil(client.pendingUserProperties?.numSpaces, "The number of spaces should not be set.")
        
        // When updating the number of spaces
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: nil, numFavouriteRooms: 4, numSpaces: 5, recoveryState: nil, verificationState: nil))
        
        // Then the new properties should be updated and the existing properties should remain unchanged
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection shouldn't have changed.")
        XCTAssertEqual(client.pendingUserProperties?.numFavouriteRooms, 4, "The number of favorite rooms should have been updated.")
        XCTAssertEqual(client.pendingUserProperties?.numSpaces, 5, "The number of spaces should have been updated.")
        
        // When updating the number of spaces
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: .Favourites, ftueUseCaseSelection: nil, numFavouriteRooms: nil, numSpaces: nil, recoveryState: nil, verificationState: nil))
        
        // Then the new properties should be updated and the existing properties should remain unchanged
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection shouldn't have changed.")
        XCTAssertEqual(client.pendingUserProperties?.numFavouriteRooms, 4, "The number of favorite rooms should have been updated.")
        XCTAssertEqual(client.pendingUserProperties?.numSpaces, 5, "The number of spaces should have been updated.")
        XCTAssertEqual(client.pendingUserProperties?.allChatsActiveFilter, .Favourites, "The All Chats active filter should have been updated.")
    }
    
    func testSendingUserProperties() {
        // Given a client with user properties set
        let client = PostHogAnalyticsClient()
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: .PersonalMessaging, numFavouriteRooms: nil, numSpaces: nil, recoveryState: nil, verificationState: nil))
        client.start()
        
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection should match.")
        
        // When sending an event (tests run under Debug configuration so this is sent to the development instance)
        let event = AnalyticsEvent.Signup(authenticationType: .Other)
        client.capture(event)
        
        // Then the properties should be cleared
        XCTAssertNil(client.pendingUserProperties, "The user properties should be cleared.")
    }
    
    func testSendingUserPropertiesWithIdentify() {
        // Given a client with user properties set
        let client = PostHogAnalyticsClient()
        client.updateUserProperties(AnalyticsEvent.UserProperties(allChatsActiveFilter: nil, ftueUseCaseSelection: .PersonalMessaging, numFavouriteRooms: nil, numSpaces: nil, recoveryState: nil, verificationState: nil))
        client.start()
        
        XCTAssertNotNil(client.pendingUserProperties, "The user properties should be cached.")
        XCTAssertEqual(client.pendingUserProperties?.ftueUseCaseSelection, .PersonalMessaging, "The use case selection should match.")
        
        // When calling identify (tests run under Debug configuration so this is sent to the development instance)
        client.identify(id: UUID().uuidString)
        
        // Then the properties should be cleared
        XCTAssertNil(client.pendingUserProperties, "The user properties should be cleared.")
    }
}
