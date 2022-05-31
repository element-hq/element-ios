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

@MainActor class AuthenticationRegistrationViewModelTests: XCTestCase {
    let defaultHomeserver = AuthenticationHomeserverViewData.mockMatrixDotOrg
    var viewModel: AuthenticationRegistrationViewModelProtocol!
    var context: AuthenticationRegistrationViewModelType.Context!
    
    @MainActor override func setUp() async throws {
        viewModel = AuthenticationRegistrationViewModel(homeserver: defaultHomeserver)
        context = viewModel.context
    }
    
    func testMatrixDotOrg() {
        // Given the initial view model configured for matrix.org with some SSO providers.
        let homeserver = defaultHomeserver
        
        // Then the view state should contain a homeserver that matches matrix.org and shows SSO buttons.
        XCTAssertEqual(context.viewState.homeserver, homeserver, "The homeserver data should match the original.")
        XCTAssertTrue(context.viewState.showSSOButtons, "The SSO buttons should be shown.")
    }
    
    func testBasicServer() {
        // Given a basic server example.com that only supports password registration.
        let homeserver = AuthenticationHomeserverViewData.mockBasicServer
        
        // When updating the view model with the server.
        viewModel.update(homeserver: homeserver)
        
        // Then the view state should be updated with the homeserver and hide the SSO buttons.
        XCTAssertEqual(context.viewState.homeserver, homeserver, "The homeserver data should should match the new homeserver.")
        XCTAssertFalse(context.viewState.showSSOButtons, "The SSO buttons should not be shown.")
    }

    func testFallbackServer() {
        // Given a basic server example.com that only supports password registration.
        let homeserver = AuthenticationHomeserverViewData.mockFallback

        // When updating the view model with the server.
        viewModel.update(homeserver: homeserver)

        // Then the view state should be updated with the homeserver and hide the SSO buttons and registration form.
        XCTAssertFalse(context.viewState.homeserver.showRegistrationForm, "The registration form should not be shown.")
        XCTAssertFalse(context.viewState.showSSOButtons, "The SSO buttons should not be shown.")
    }
    
    func testUsernameError() async throws {
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
        try await Task.sleep(nanoseconds: 100_000_000)
        
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
