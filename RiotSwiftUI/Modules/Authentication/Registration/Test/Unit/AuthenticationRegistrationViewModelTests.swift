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
import Combine

@testable import RiotSwiftUI

@available(iOS 14.0, *)
@MainActor class AuthenticationRegistrationViewModelTests: XCTestCase {
    var viewModel: AuthenticationRegistrationViewModelProtocol!
    var context: AuthenticationRegistrationViewModelType.Context!
    
    @MainActor override func setUp() async throws {
        viewModel = AuthenticationRegistrationViewModel(homeserverAddress: "", ssoIdentityProviders: [])
        context = viewModel.context
    }
    
    func testMatrixDotOrg() {
        // Given matrix.org with some SSO providers.
        let address = "https://matrix.org"
        let ssoProviders = [
            SSOIdentityProvider(id: "apple", name: "Apple", brand: "Apple", iconURL: nil),
            SSOIdentityProvider(id: "google", name: "Google", brand: "Google", iconURL: nil),
            SSOIdentityProvider(id: "github", name: "Github", brand: "Github", iconURL: nil)
        ]
        
        // When updating the view model with the server.
        viewModel.update(homeserverAddress: address, showRegistrationForm: true, ssoIdentityProviders: ssoProviders)
        
        // Then the form should show the server description along with the username and password fields and the SSO buttons.
        XCTAssertEqual(context.viewState.homeserverAddress, "matrix.org", "The homeserver address should have the https scheme stripped away.")
        XCTAssertEqual(context.viewState.serverDescription, VectorL10n.authenticationRegistrationMatrixDescription, "A description should be shown for matrix.org.")
        XCTAssertTrue(context.viewState.showRegistrationForm, "The username and password section should be shown.")
        XCTAssertTrue(context.viewState.showSSOButtons, "The SSO buttons should be shown.")
    }
    
    func testBasicServer() {
        // Given a basic server example.com that only supports password registration.
        let address = "https://example.com"
        
        // When updating the view model with the server.
        viewModel.update(homeserverAddress: address, showRegistrationForm: true, ssoIdentityProviders: [])
        
        // Then the form should only show the username and password section.
        XCTAssertEqual(context.viewState.homeserverAddress, "example.com", "The homeserver address should have the https scheme stripped away.")
        XCTAssertNil(context.viewState.serverDescription, "A description should not be shown when the server isn't matrix.org.")
        XCTAssertTrue(context.viewState.showRegistrationForm, "The username and password section should be shown.")
        XCTAssertFalse(context.viewState.showSSOButtons, "The SSO buttons should not be shown.")
    }
    
    func testUnsecureServer() {
        // Given a server that uses http for communication.
        let address = "http://testserver.local"
        
        // When updating the view model with the server.
        viewModel.update(homeserverAddress: address, showRegistrationForm: true, ssoIdentityProviders: [])
        
        // Then the form should only show the username and password section.
        XCTAssertEqual(context.viewState.homeserverAddress, address, "The homeserver address should show the http scheme.")
        XCTAssertNil(context.viewState.serverDescription, "A description should not be shown when the server isn't matrix.org.")
    }
    
    func testSSOOnlyServer() {
        // Given matrix.org with some SSO providers.
        let address = "https://example.com"
        let ssoProviders = [
            SSOIdentityProvider(id: "apple", name: "Apple", brand: "Apple", iconURL: nil),
            SSOIdentityProvider(id: "google", name: "Google", brand: "Google", iconURL: nil),
            SSOIdentityProvider(id: "github", name: "Github", brand: "Github", iconURL: nil)
        ]
        
        // When updating the view model with the server.
        viewModel.update(homeserverAddress: address, showRegistrationForm: false, ssoIdentityProviders: ssoProviders)
        
        // Then the form should show the server description along with the username and password fields and the SSO buttons.
        XCTAssertEqual(context.viewState.homeserverAddress, "example.com", "The homeserver address should have the https scheme stripped away.")
        XCTAssertNil(context.viewState.serverDescription, "A description should not be shown when the server isn't matrix.org.")
        XCTAssertFalse(context.viewState.showRegistrationForm, "The username and password section should not be shown.")
        XCTAssertTrue(context.viewState.showSSOButtons, "The SSO buttons should be shown.")
    }
    
    func testUsernameError() async {
        // Given a form with a valid username.
        context.username = "bob"
        XCTAssertNil(context.viewState.usernameErrorMessage, "The shouldn't be a username error when the view model is created.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, VectorL10n.authenticationRegistrationUsernameFooter, "The standard footer message should be shown.")
        XCTAssertTrue(context.viewState.isUsernameValid, "The username should be valid if there is no error.")
        
        // When displaying the error as a username error.
        let errorMessage = "Username unavailable"
        viewModel.displayError(.usernameUnavailable(errorMessage))
        
        // Then the error should be shown in the footer.
        XCTAssertEqual(context.viewState.usernameErrorMessage, errorMessage, "The error message should be stored.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, errorMessage, "The error message should replace the standard footer message.")
        XCTAssertFalse(context.viewState.isUsernameValid, "The username should be invalid when an error is shown.")
        
        
        // When clearing the error.
        context.send(viewAction: .clearUsernameError)
        
        // Wait for the action to spawn a Task on the main actor as the Context protocol doesn't support actors.
        let task = Task { try await Task.sleep(nanoseconds: 100_000_000) }
        _ = await task.result
        
        // Then the error should be hidden again.
        XCTAssertNil(context.viewState.usernameErrorMessage, "The shouldn't be a username error anymore.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, VectorL10n.authenticationRegistrationUsernameFooter, "The standard footer message should be shown again.")
        XCTAssertTrue(context.viewState.isUsernameValid, "The username should be valid when an error is cleared.")
    }
    
    func testEmptyUsernameWithShortPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.isPasswordValid, "An empty password should be invalid.")
        XCTAssertFalse(context.viewState.isUsernameValid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a password of 7 characters without a username.
        context.username = ""
        context.password = "1234567"
        
        // Then the credentials should remain invalid.
        XCTAssertFalse(context.viewState.isPasswordValid, "A 7-character password should be invalid.")
        XCTAssertFalse(context.viewState.isUsernameValid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testEmptyUsernameWithValidPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.isPasswordValid, "An empty password should be invalid.")
        XCTAssertFalse(context.viewState.isUsernameValid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a password of 8 characters without a username.
        context.username = ""
        context.password = "12345678"
        
        // Then the password should be valid but the credentials should still be invalid.
        XCTAssertTrue(context.viewState.isPasswordValid, "An 8-character password should be valid.")
        XCTAssertFalse(context.viewState.isUsernameValid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testValidUsernameWithEmptyPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.isPasswordValid, "An empty password should be invalid.")
        XCTAssertFalse(context.viewState.isUsernameValid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a username without a password.
        context.username = "bob"
        context.password = ""
        
        // Then the username should be valid but the credentials should still be invalid.
        XCTAssertFalse(context.viewState.isPasswordValid, "An empty password should be invalid.")
        XCTAssertTrue(context.viewState.isUsernameValid, "The username should be valid when there is no error.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testUsernameErrorWithValidPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.isPasswordValid, "An empty password should be invalid.")
        XCTAssertFalse(context.viewState.isUsernameValid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a username and password and encountering a username error
        context.username = "bob"
        context.password = "12345678"
        
        let errorMessage = "Username unavailable"
        viewModel.displayError(.usernameUnavailable(errorMessage))
        
        // Then the password should be valid but the credentials should still be invalid.
        XCTAssertTrue(context.viewState.isPasswordValid, "An 8-character password should be valid.")
        XCTAssertFalse(context.viewState.isUsernameValid, "The username should be invalid when an error is shown.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testValidCredentials() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.isPasswordValid, "An empty password should be invalid.")
        XCTAssertFalse(context.viewState.isUsernameValid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a username and an 8-character password.
        context.username = "bob"
        context.password = "12345678"
        
        // Then the credentials should be considered valid.
        XCTAssertTrue(context.viewState.isPasswordValid, "An 8-character password should be valid.")
        XCTAssertTrue(context.viewState.isUsernameValid, "The username should be valid when there is no error.")
        XCTAssertTrue(context.viewState.hasValidCredentials, "The credentials should be valid when the username and password are valid.")
    }
}
