// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
@testable import Element

class OnboardingTests: XCTestCase {
    
    let userId = "@test:matrix.org"
    
    override func setUp() {
        // Clear any properties for the test
        UserSessionProperties(userId: userId).delete()
    }
    
    func testEmptyUseCase() {
        // Given an empty set of user properties
        let properties = UserSessionProperties(userId: userId)
        
        // Then the use case property should return nil
        XCTAssertNil(properties.useCase, "A use case has not been set")
    }
    
    func testPersonalMessagingUseCase() {
        // Given an empty set of user properties
        let properties = UserSessionProperties(userId: userId)
        
        // When storing a use case result of personal messaging
        let result = OnboardingUseCaseViewModelResult.personalMessaging
        properties.useCase = result.userSessionPropertyValue
        
        // Then the use case property should return personal messaging
        XCTAssertEqual(properties.useCase, .personalMessaging, "The use case should be Personal Messaging")
    }
    
    func testSkippedUseCase() {
        // Given an empty set of user properties
        let properties = UserSessionProperties(userId: userId)
        
        // When storing a skipped use case result
        let result = OnboardingUseCaseViewModelResult.skipped
        properties.useCase = result.userSessionPropertyValue
        
        // Then the use case property should return skipped
        XCTAssertEqual(properties.useCase, .skipped)
    }
    
    func testUseCaseAfterDeletingProperties() {
        // Given a set of user properties with the Work Messaging use case
        let properties = UserSessionProperties(userId: userId)
        let result = OnboardingUseCaseViewModelResult.workMessaging
        properties.useCase = result.userSessionPropertyValue
        XCTAssertEqual(properties.useCase, .workMessaging, "The use case should be Work Messaging")
        
        // When deleting the user properties
        properties.delete()
        
        // Then the use case property should return nil
        XCTAssertNil(properties.useCase)
    }
    
    func testUseCasePersistence() {
        // Given a set of user properties with the Personal Messaging use case
        var properties: UserSessionProperties? = UserSessionProperties(userId: userId)
        let result = OnboardingUseCaseViewModelResult.personalMessaging
        properties?.useCase = result.userSessionPropertyValue
        XCTAssertEqual(properties?.useCase, .personalMessaging, "The use case should be Personal Messaging")
        
        // When the app is relaunched and a new user properties instance is creates
        properties = nil
        let newProperties = UserSessionProperties(userId: userId)
        
        // Then the use case property should still return Personal Messaging
        XCTAssertEqual(newProperties.useCase, .personalMessaging, "The use case should be Personal Messaging")
    }
    
}
