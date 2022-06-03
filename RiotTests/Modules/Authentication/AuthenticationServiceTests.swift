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
        try await service.startFlow(.register, for: "https://matrix.org")
        
        // Then a registration wizard should be available for use.
        XCTAssertNotNil(service.registrationWizard, "The registration wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.state.homeserver.registrationFlow, "The supported registration flow should be stored after starting a registration flow.")
    }
    
    func testReset() async throws {
        // Given a service that has begun registration.
        let service = AuthenticationService()
        try await service.startFlow(.register, for: "https://matrix.org")
        _ = try await service.registrationWizard?.createAccount(username: UUID().uuidString, password: UUID().uuidString, initialDeviceDisplayName: "Test")
        XCTAssertNotNil(service.loginWizard, "The login wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.registrationWizard, "The registration wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.state.homeserver.registrationFlow, "The supported registration flow should be stored after starting a registration flow.")
        XCTAssertTrue(service.isRegistrationStarted, "The service should show as having started registration.")
        XCTAssertEqual(service.state.flow, .register, "The service should show as using a registration flow.")
        
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
    
    func testHomeserverViewDataForMatrixDotOrg() {
        // Given a homeserver such as matrix.org.
        let address = "https://matrix-client.matrix.org"
        let addressFromUser = "https://matrix.org" // https is added when sanitising the input.
        let ssoIdentityProviders = [
            SSOIdentityProvider(id: "1", name: "Apple", brand: "apple", iconURL: nil),
            SSOIdentityProvider(id: "2", name: "GitHub", brand: "github", iconURL: nil)
        ]
        let flowResult = FlowResult(missingStages: [.email(isMandatory: true), .reCaptcha(isMandatory: true, siteKey: "1234")], completedStages: [])
        let homeserver = AuthenticationState.Homeserver(address: address,
                                                        addressFromUser: addressFromUser,
                                                        preferredLoginMode: .ssoAndPassword(ssoIdentityProviders: ssoIdentityProviders),
                                                        registrationFlow: .flowResponse(flowResult))
        
        // When creating view data for that homeserver.
        let viewData = homeserver.viewData
        
        // Then the view data should correctly represent the homeserver.
        XCTAssertEqual(viewData.address, "matrix.org", "The displayed address should match the address supplied by the user, but without the scheme.")
        XCTAssertEqual(viewData.isMatrixDotOrg, true, "The server should be detected as matrix.org.")
        XCTAssertTrue(viewData.showLoginForm, "The login form should be shown.")
        XCTAssertEqual(viewData.ssoIdentityProviders, ssoIdentityProviders, "The sso identity providers should match.")
        XCTAssertTrue(viewData.showRegistrationForm, "The registration form should be shown.")
    }
    
    func testHomeserverViewDataForPasswordLoginOnly() {
        // Given a homeserver with password login and registration disabled.
        let address = "https://matrix.example.com"
        let addressFromUser = "https://example.com" // https is added when sanitising the input.
        let homeserver = AuthenticationState.Homeserver(address: address,
                                                        addressFromUser: addressFromUser,
                                                        preferredLoginMode: .password,
                                                        registrationFlow: nil)
        
        // When creating view data for that homeserver.
        let viewData = homeserver.viewData
        
        // Then the view data should correctly represent the homeserver.
        XCTAssertEqual(viewData.address, "example.com", "The displayed address should match the address supplied by the user, but without the scheme.")
        XCTAssertEqual(viewData.isMatrixDotOrg, false, "The server should not be detected as matrix.org.")
        XCTAssertTrue(viewData.showLoginForm, "The login form should be shown.")
        XCTAssertEqual(viewData.ssoIdentityProviders, [], "There shouldn't be any sso identity providers.")
        XCTAssertFalse(viewData.showRegistrationForm, "The registration form should not be shown.")
    }
    
    func testHomeserverViewDataForSSOOnly() {
        // Given a homeserver that only supports authentication via SSO.
        let address = "https://matrix.company.com"
        let addressFromUser = "https://company.com" // https is added when sanitising the input.
        let ssoIdentityProviders = [SSOIdentityProvider(id: "1", name: "SAML", brand: nil, iconURL: nil)]
        let homeserver = AuthenticationState.Homeserver(address: address,
                                                        addressFromUser: addressFromUser,
                                                        preferredLoginMode: .sso(ssoIdentityProviders: ssoIdentityProviders),
                                                        registrationFlow: nil)
        
        // When creating view data for that homeserver.
        let viewData = homeserver.viewData
        
        // Then the view data should correctly represent the homeserver.
        XCTAssertEqual(viewData.address, "company.com", "The displayed address should match the address supplied by the user, but without the scheme.")
        XCTAssertEqual(viewData.isMatrixDotOrg, false, "The server should not be detected as matrix.org.")
        XCTAssertFalse(viewData.showLoginForm, "The login form should not be shown.")
        XCTAssertEqual(viewData.ssoIdentityProviders, ssoIdentityProviders, "The sso identity providers should match.")
        XCTAssertFalse(viewData.showRegistrationForm, "The registration form should not be shown.")
    }
    
    func testHomeserverViewDataForLocalHomeserver() {
        // Given a local homeserver that supports login and registration but only via a password.
        let addressFromUser = "http://localhost:8008" // https is added when sanitising the input.
        let flowResult = FlowResult(missingStages: [.dummy(isMandatory: true)], completedStages: [])
        let homeserver = AuthenticationState.Homeserver(address: addressFromUser,
                                                        addressFromUser: addressFromUser,
                                                        preferredLoginMode: .password,
                                                        registrationFlow: .flowResponse(flowResult))
        
        // When creating view data for that homeserver.
        let viewData = homeserver.viewData
        
        // Then the view data should correctly represent the homeserver.
        XCTAssertEqual(viewData.address, "http://localhost:8008", "The displayed address should match address supplied by the user, complete with the scheme.")
        XCTAssertEqual(viewData.isMatrixDotOrg, false, "The server should not be detected as matrix.org.")
        XCTAssertTrue(viewData.showLoginForm, "The login form should be shown.")
        XCTAssertEqual(viewData.ssoIdentityProviders, [], "There shouldn't be any sso identity providers.")
        XCTAssertTrue(viewData.showRegistrationForm, "The registration form should be shown.")
    }
}
