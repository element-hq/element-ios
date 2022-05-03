// 
// Copyright 2022 New Vector Ltd
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

@available(iOS 14.0, *)
class AuthenticationServiceTests: XCTestCase {
    func testRegistrationWizardWhenStartingLoginFlow() async throws {
        // Given a fresh service.
        let service = AuthenticationService()
        XCTAssertNil(service.registrationWizard, "A new service shouldn't have a registration wizard.")
        
        // When starting a new login flow.
        try await service.startFlow(.login, for: "https://matrix.org")
        
        // Then a registration wizard shouldn't have been created.
        XCTAssertNil(service.registrationWizard, "The registration wizard should not exist if startFlow was called for login.")
    }
    
    func testRegistrationWizard() async throws {
        // Given a fresh service.
        let service = AuthenticationService()
        XCTAssertNil(service.registrationWizard, "A new service shouldn't provide a registration wizard.")
        XCTAssertNil(service.state.homeserver.registrationFlow, "A new service shouldn't provide a registration flow for the homeserver.")
        
        // When starting a new registration flow.
        try await service.startFlow(.registration, for: "https://matrix.org")
        
        // Then a registration wizard should be available for use.
        XCTAssertNotNil(service.registrationWizard, "The registration wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.state.homeserver.registrationFlow, "The supported registration flow should be stored after starting a registration flow.")
    }
    
    func testReset() async throws {
        // Given a service that has begun registration.
        let service = AuthenticationService()
        try await service.startFlow(.registration, for: "https://matrix.org")
        _ = try await service.registrationWizard?.createAccount(username: UUID().uuidString, password: UUID().uuidString, initialDeviceDisplayName: "Test")
        XCTAssertNotNil(service.loginWizard, "The login wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.registrationWizard, "The registration wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.state.homeserver.registrationFlow, "The supported registration flow should be stored after starting a registration flow.")
        XCTAssertTrue(service.isRegistrationStarted, "The service should show as having started registration.")
        XCTAssertEqual(service.state.flow, .registration, "The service should show as using a registration flow.")
        
        // When resetting the service.
        service.reset()
        
        // Then the wizards should no longer exist.
        XCTAssertNil(service.loginWizard, "The login wizard should be cleared after calling reset.")
        XCTAssertNil(service.registrationWizard, "The registration wizard should be cleared after calling reset.")
        XCTAssertNil(service.state.homeserver.registrationFlow, "The supported registration flow should be cleared when calling reset.")
        XCTAssertFalse(service.isRegistrationStarted, "The service should not indicate it has started registration after calling reset.")
        XCTAssertEqual(service.state.flow, .login, "The flow should have been set back to login when calling reset.")
    }
    
    func testHomeserverState() async throws {
        // Given a service that has begun login for one homeserver.
        let service = AuthenticationService()
        try await service.startFlow(.login, for: "https://glasgow.social")
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://glasgow.social", "The initial address entered by the user should be stored.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix.glasgow.social", "The initial address discovered from the well-known should be stored.")
        
        // When switching to a different homeserver
        try await service.startFlow(.login, for: "https://matrix.org")
        
        // The the homeserver state should update to represent the new server
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://matrix.org", "The new address entered by the user should be stored.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix-client.matrix.org", "The new address discovered from the well-known should be stored.")
    }
}
