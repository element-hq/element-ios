// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

@MainActor class AuthenticationServiceTests: XCTestCase {
    var service: AuthenticationService!
    
    /// Makes a new service configured for testing.
    @MainActor override func setUp() {
        service = AuthenticationService(sessionCreator: MockSessionCreator())
        service.clientType = MockAuthenticationRestClient.self
    }
    
    // MARK: - Service State
    
    func testWizardsWhenStartingLoginFlow() async throws {
        // Given a fresh service.
        XCTAssertNil(service.loginWizard, "A new service shouldn't have a login wizard.")
        XCTAssertNil(service.registrationWizard, "A new service shouldn't have a registration wizard.")
        
        // When starting a new login flow.
        try await service.startFlow(.login, for: "https://matrix.org")
        
        // Then a registration wizard shouldn't have been created.
        XCTAssertNotNil(service.loginWizard, "The login wizard should exist after starting a login flow.")
        XCTAssertNil(service.registrationWizard, "The registration wizard should not exist if startFlow was called for login.")
    }
    
    func testWizardsWhenStartingRegistrationFlow() async throws {
        // Given a fresh service.
        XCTAssertNil(service.loginWizard, "A new service shouldn't have a login wizard.")
        XCTAssertNil(service.registrationWizard, "A new service shouldn't provide a registration wizard.")
        XCTAssertNil(service.state.homeserver.registrationFlow, "A new service shouldn't provide a registration flow for the homeserver.")
        
        // When starting a new registration flow.
        try await service.startFlow(.register, for: "https://matrix.org")
        
        // Then a registration wizard should be available for use.
        XCTAssertNotNil(service.loginWizard, "The login wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.registrationWizard, "The registration wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.state.homeserver.registrationFlow, "The supported registration flow should be stored after starting a registration flow.")
    }
    
    func testReset() async throws {
        // Given a service that has begun registration.
        try await service.startFlow(.register, for: "https://example.com")
        _ = try await service.registrationWizard?.createAccount(username: UUID().uuidString, password: UUID().uuidString, initialDeviceDisplayName: "Test")
        XCTAssertNotNil(service.loginWizard, "The login wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.registrationWizard, "The registration wizard should exist after starting a registration flow.")
        XCTAssertNotNil(service.state.homeserver.registrationFlow, "The supported registration flow should be stored after starting a registration flow.")
        XCTAssertTrue(service.isRegistrationStarted, "The service should show as having started registration.")
        XCTAssertEqual(service.state.flow, .register, "The service should show as using a registration flow.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix.example.com", "The actual homeserver address should be discovered.")
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://example.com", "The address from the startFlow call should be stored.")
        
        // When resetting the service.
        service.reset()
        
        // Then the wizards should no longer exist, but the chosen server should be remembered.
        XCTAssertNil(service.loginWizard, "The login wizard should be cleared after calling reset.")
        XCTAssertNil(service.registrationWizard, "The registration wizard should be cleared after calling reset.")
        XCTAssertNil(service.state.homeserver.registrationFlow, "The supported registration flow should be cleared when calling reset.")
        XCTAssertFalse(service.isRegistrationStarted, "The service should not indicate it has started registration after calling reset.")
        XCTAssertEqual(service.state.flow, .login, "The flow should have been set back to login when calling reset.")
        XCTAssertEqual(service.state.homeserver.address, "https://example.com", "The address should reset to the value entered by the user.")
    }
    
    func testResetDefaultServer() async throws {
        // Given a service that has begun login on one server.
        try await service.startFlow(.login, for: "https://example.com")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix.example.com", "The actual homeserver address should be discovered.")
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://example.com", "The address from the startFlow call should be stored.")
        
        // When resetting the service to use the default server.
        service.reset(useDefaultServer: true)
        
        // Then the service should reset back to the default server.
        XCTAssertEqual(service.state.homeserver.address, BuildSettings.serverConfigDefaultHomeserverUrlString,
                       "The address should reset to the value configured in the build settings.")
    }
    
    func testProvisioningLink() async throws {
        // Given a service that has begun login using a provisioning link.
        let homeserverURL = "https://example.com"
        let provisioningLink = URL(string: "app.element.io/register/?hs_url=\(homeserverURL)")!
        let universalLink = UniversalLink(url: provisioningLink)
        service.handleServerProvisioningLink(universalLink)
        
        try await service.startFlow(.login)
        XCTAssertEqual(universalLink.homeserverUrl, homeserverURL)
        XCTAssertNotNil(service.provisioningLink, "The provisioning link should be stored in the service.")
        XCTAssertEqual(service.provisioningLink?.homeserverUrl, homeserverURL, "The provisioning link's homeserver should not change.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix.example.com", "The actual homeserver address should be discovered.")
        XCTAssertEqual(service.state.homeserver.addressFromUser, homeserverURL, "The address from the provisioning link should be stored.")
        
        // When resetting the service.
        service.reset()
        
        // Then the link should be remembered.
        XCTAssertNotNil(service.provisioningLink, "The provisioning link should not be cleared.")
        XCTAssertEqual(service.provisioningLink?.homeserverUrl, homeserverURL, "The provisioning link's homeserver should not change.")
        XCTAssertEqual(service.state.homeserver.address, homeserverURL, "The address from the provisioning link should be stored.")
        XCTAssertNil(service.state.homeserver.addressFromUser, "There shouldn't be an address from the user after resetting the service.")
        
        // When resetting the service back to the default server.
        service.reset(useDefaultServer: true)
        
        // Then the link should be forgotten.
        XCTAssertNil(service.provisioningLink, "The provisioning link should be forgotten after resetting back to the default server.")
        XCTAssertNil(service.state.homeserver.addressFromUser, "There shouldn't be an address from the user after resetting the service.")
        XCTAssertEqual(service.state.homeserver.address, BuildSettings.serverConfigDefaultHomeserverUrlString,
                       "The address should reset to the value configured in the build settings.")
    }
    
    func testHomeserverState() async throws {
        // Given a service that has begun login for one homeserver.
        try await service.startFlow(.login, for: "https://example.com")
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://example.com", "The initial address entered by the user should be stored.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix.example.com", "The initial address discovered from the well-known should be stored.")
        
        // When switching to a different homeserver
        try await service.startFlow(.login, for: "https://matrix.org")
        
        // The the homeserver state should update to represent the new server
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://matrix.org", "The new address entered by the user should be stored.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix-client.matrix.org", "The new address discovered from the well-known should be stored.")
    }
    
    func testStartingLoginWithInvalidURL() async throws {
        // Given a service that has started the register flow for one homeserver.
        try await service.startFlow(.login, for: "https://example.com")
        XCTAssertEqual(service.client.homeserver, "https://matrix.example.com", "The client should be set up for the homeserver")
        XCTAssertEqual(service.state.flow, .login, "The flow should be set as login.")
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://example.com", "The initial address entered by the user should be stored.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix.example.com", "The initial address discovered from the well-known should be stored.")
        
        // When failing to start login by entering an invalid address.
        do {
            try await service.startFlow(.login, for: "https://google.com")
            XCTFail("The registration flow should fail for an incorrect homeserver address.")
        } catch {
            XCTAssertNotNil(error, "The client should throw an error for an incorrect address.")
        }
        
        // Then the service's state and client should be unchanged.
        XCTAssertEqual(service.client.homeserver, "https://matrix.example.com", "The client should be set up for the homeserver")
        XCTAssertEqual(service.state.flow, .login, "The flow should still be set as login.")
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://example.com", "The initial address entered by the user should be stored.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix.example.com", "The initial address discovered from the well-known should be stored.")
    }
    
    func testStartingRegistrationForLoginOnlyServer() async throws {
        // Given a service that has started the register flow for one homeserver.
        try await service.startFlow(.register, for: "https://example.com")
        XCTAssertEqual(service.client.homeserver, "https://matrix.example.com", "The client should be set up for the homeserver")
        XCTAssertEqual(service.state.flow, .register, "The flow should be set as registration.")
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://example.com", "The initial address entered by the user should be stored.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix.example.com", "The initial address discovered from the well-known should be stored.")
        
        // When failing to start registration for another homeserver that only supports login.
        do {
            try await service.startFlow(.register, for: "https://private.com")
            XCTFail("The registration flow should fail for a server that doesn't support registration")
        } catch {
            XCTAssertEqual(error as? MockAuthenticationRestClient.MockError, MockAuthenticationRestClient.MockError.registrationDisabled,
                           "The client should throw with disabled registration.")
        }
        
        // The the service's state and client should be unchanged.
        XCTAssertEqual(service.client.homeserver, "https://matrix.example.com", "The client should still be set up for the homeserver")
        XCTAssertEqual(service.state.flow, .register, "The flow should still be set as registration.")
        XCTAssertEqual(service.state.homeserver.addressFromUser, "https://example.com", "The initial address entered by the user should still be stored.")
        XCTAssertEqual(service.state.homeserver.address, "https://matrix.example.com", "The initial address discovered from the well-known should still be stored.")
    }
    
    func testPasswordLogin() async throws {
        // Given a server ready for login.
        try await service.startFlow(.login, for: "https://matrix.org")
        guard let loginWizard = service.loginWizard else {
            XCTFail("The login wizard should exist after starting a login flow.")
            return
        }
        
        // When logging in with valid credentials.
        let account = MockAuthenticationRestClient.registeredAccount
        let session = try await loginWizard.login(login: account.username,
                                                  password: account.password,
                                                  initialDeviceName: UIDevice.current.initialDisplayName)
        
        // Then the MXSession should be created for the user ID.
        XCTAssertEqual(session.myUserId, "@alice:matrix.org")
    }
    
    func testBasicRegistration() async throws {
        // Given a basic server ready for registration (only has a dummy stage).
        try await service.startFlow(.register, for: "https://example.com")
        guard let registrationWizard = service.registrationWizard else {
            XCTFail("The registration wizard should exist after starting a registration flow.")
            return
        }
        
        // When registering with a username and password.
        let result = try await registrationWizard.createAccount(username: "bob",
                                                                password: "password",
                                                                initialDeviceDisplayName: "whatever")
        
        // Then an MXSession should be created for the new account.
        guard case let .success(session) = result else {
            XCTFail("The dummy stage should be performed and registration should be successful.")
            return
        }
        XCTAssertEqual(session.myUserId, "@bob:example.com")
    }
    
    func testInteractiveRegistration() async throws {
        // Given a server ready for registration with multiple mandatory stages.
        try await service.startFlow(.register, for: "https://matrix.org")
        guard let registrationWizard = service.registrationWizard else {
            XCTFail("The registration wizard should exist after starting a registration flow.")
            return
        }
        XCTAssertFalse(registrationWizard.state.isRegistrationStarted, "Registration should not be started yet.")
        
        // When registering with a username and password.
        let createAccountResult = try await registrationWizard.createAccount(username: "bob",
                                                                             password: "password",
                                                                             initialDeviceDisplayName: "whatever")
        
        // Then the registration should be started and be waiting for all of the stages to be completed.
        guard case let .flowResponse(flowResult) = createAccountResult else {
            XCTFail("The registration should not have completed.")
            return
        }
        XCTAssertEqual(flowResult.completedStages.count, 0)
        XCTAssertEqual(flowResult.missingStages.count, 3)
        XCTAssertTrue(registrationWizard.state.isRegistrationStarted, "Registration should be started after calling create account.")
        
        // TODO: Email step
        
        // When performing the terms stage.
        let termsResult = try await registrationWizard.acceptTerms()
        
        // Then the completed and missing stages should be updated accordingly.
        guard case let .flowResponse(termsFlowResult) = termsResult else {
            XCTFail("The registration should not have completed.")
            return
        }
        XCTAssertEqual(termsFlowResult.completedStages.count, 1)
        XCTAssertEqual(termsFlowResult.missingStages.count, 2)
        
        // When performing the ReCaptcha stage.
        let reCaptchaResult = try await registrationWizard.performReCaptcha(response: "trafficlights")
        
        // Then the completed and missing stages should be updated accordingly.
        guard case let .flowResponse(reCaptchaFlowResult) = reCaptchaResult else {
            XCTFail("The registration should not have completed.")
            return
        }
        XCTAssertEqual(reCaptchaFlowResult.completedStages.count, 2)
        XCTAssertEqual(reCaptchaFlowResult.missingStages.count, 1)
    }
    
    // MARK: - Homeserver View Data
    
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
                                                        preferredLoginMode: .sso(ssoIdentityProviders: ssoIdentityProviders, providesDelegatedOIDCCompatibility: false),
                                                        registrationFlow: nil)
        
        // When creating view data for that homeserver.
        let viewData = homeserver.viewData
        
        // Then the view data should correctly represent the homeserver.
        XCTAssertEqual(viewData.address, "company.com", "The displayed address should match the address supplied by the user, but without the scheme.")
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
        XCTAssertTrue(viewData.showLoginForm, "The login form should be shown.")
        XCTAssertEqual(viewData.ssoIdentityProviders, [], "There shouldn't be any sso identity providers.")
        XCTAssertTrue(viewData.showRegistrationForm, "The registration form should be shown.")
    }
    
    func testLogsForPassword() {
        // Given all of the coordinator and view model results that contain passwords.
        let password = "supersecretpassword"
        let loginViewModelResult: AuthenticationLoginViewModelResult = .login(username: "Alice", password: password)
        let loginCoordinatorResult: AuthenticationLoginCoordinatorResult = .success(session: MXSession(), password: password)
        let registerViewModelResult: AuthenticationRegistrationViewModelResult = .createAccount(username: "Alice", password: password)
        let registerCoordinatorResult: AuthenticationRegistrationCoordinatorResult = .completed(result: RegistrationResult.success(MXSession()), password: password)
        let softLogoutViewModelResult: AuthenticationSoftLogoutViewModelResult = .login(password)
        let softLogoutCoordinatorResult: AuthenticationSoftLogoutCoordinatorResult = .success(session: MXSession(), password: password)
        let forgotPasswordResult: AuthenticationChoosePasswordViewModelResult = .submit(password, false)
        let changePasswordResult: ChangePasswordViewModelResult = .submit(oldPassword: password, newPassword: password, signoutAllDevices: false)
        
        // When creating a string representation of those results (e.g. for logging).
        let loginViewModelString = "\(loginViewModelResult)"
        let loginCoordinatorString = "\(loginCoordinatorResult)"
        let registerViewModelString = "\(registerViewModelResult)"
        let registerCoordinatorString = "\(registerCoordinatorResult)"
        let softLogoutViewModelString = "\(softLogoutViewModelResult)"
        let softLogoutCoordinatorString = "\(softLogoutCoordinatorResult)"
        let forgotPasswordString = "\(forgotPasswordResult)"
        let changePasswordString = "\(changePasswordResult)"
        
        // Then the password should not be included in that string.
        XCTAssertFalse(loginViewModelString.contains(password), "The password must not be included in any strings.")
        XCTAssertFalse(loginCoordinatorString.contains(password), "The password must not be included in any strings.")
        XCTAssertFalse(registerViewModelString.contains(password), "The password must not be included in any strings.")
        XCTAssertFalse(registerCoordinatorString.contains(password), "The password must not be included in any strings.")
        XCTAssertFalse(softLogoutViewModelString.contains(password), "The password must not be included in any strings.")
        XCTAssertFalse(softLogoutCoordinatorString.contains(password), "The password must not be included in any strings.")
        XCTAssertFalse(forgotPasswordString.contains(password), "The password must not be included in any strings.")
        XCTAssertFalse(changePasswordString.contains(password), "The password must not be included in any strings.")
    }
    
    func testHomeserverAddressSanitization() {
        let basicAddress = "matrix.org"
        let httpAddress = "http://localhost"
        let trailingSlashAddress = "https://matrix.example.com/"
        let whitespaceAddress = " https://matrix.example.com/  "
        let validAddress = "https://matrix.example.com"
        let validAddressWithPort = "https://matrix.example.com:8484"
        
        let sanitizedBasicAddress = HomeserverAddress.sanitized(basicAddress)
        let sanitizedHTTPAddress = HomeserverAddress.sanitized(httpAddress)
        let sanitizedTrailingSlashAddress = HomeserverAddress.sanitized(trailingSlashAddress)
        let sanitizedWhitespaceAddress = HomeserverAddress.sanitized(whitespaceAddress)
        let sanitizedValidAddress = HomeserverAddress.sanitized(validAddress)
        let sanitizedValidAddressWithPort = HomeserverAddress.sanitized(validAddressWithPort)
        
        XCTAssertEqual(sanitizedBasicAddress, "https://matrix.org")
        XCTAssertEqual(sanitizedHTTPAddress, "http://localhost")
        XCTAssertEqual(sanitizedTrailingSlashAddress, "https://matrix.example.com")
        XCTAssertEqual(sanitizedWhitespaceAddress, "https://matrix.example.com")
        XCTAssertEqual(sanitizedValidAddress, validAddress)
        XCTAssertEqual(sanitizedValidAddressWithPort, validAddressWithPort)
    }
}
