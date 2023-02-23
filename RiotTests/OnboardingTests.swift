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
