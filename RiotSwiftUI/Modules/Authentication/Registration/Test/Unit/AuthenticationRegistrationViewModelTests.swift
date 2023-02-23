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

import Combine
import XCTest

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
        // Given a form with an entered username.
        context.username = "bob"
        XCTAssertEqual(context.viewState.usernameAvailability, .unknown, "The username availability should be unknown when the view model is created.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, VectorL10n.authenticationRegistrationUsernameFooter, "The standard footer message should be shown.")
        XCTAssertFalse(context.viewState.isUsernameInvalid, "The username should be valid if there is no error.")
        
        // When displaying the error as a username error.
        let errorMessage = "Username unavailable"
        viewModel.displayError(.usernameUnavailable(errorMessage))
        
        // Then the error should be shown in the footer.
        guard case let .invalid(displayedError) = context.viewState.usernameAvailability else {
            XCTFail("The username should be invalid when an error is shown.")
            return
        }
        XCTAssertEqual(displayedError, errorMessage, "The error message should match.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, errorMessage, "The error message should replace the standard footer message.")
        XCTAssertTrue(context.viewState.isUsernameInvalid, "The username should be invalid when an error is shown.")
        
        // When clearing the error.
        context.send(viewAction: .resetUsernameAvailability)
        
        // Wait for the action to spawn a Task on the main actor as the Context protocol doesn't support actors.
        await Task.yield()
        
        // Then the error should be hidden again.
        XCTAssertEqual(context.viewState.usernameAvailability, .unknown, "The username availability should return to an unknown state.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, VectorL10n.authenticationRegistrationUsernameFooter, "The standard footer message should be shown again.")
        XCTAssertFalse(context.viewState.isUsernameInvalid, "The username should be valid when an error is cleared.")
    }
    
    func testUsernameAvailability() async throws {
        // Given a form with an entered username.
        context.username = "bob"
        XCTAssertEqual(context.viewState.usernameAvailability, .unknown, "The username availability should be unknown when the view model is created.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, VectorL10n.authenticationRegistrationUsernameFooter, "The standard footer message should be shown.")
        XCTAssertFalse(context.viewState.isUsernameInvalid, "The username should be valid if there is no error.")
        
        // When updating the state for an available username
        viewModel.confirmUsernameAvailability("bob")
        
        // Then the error should be shown in the footer.
        XCTAssertEqual(context.viewState.usernameAvailability, .available,
                       "The username should be detected as available.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, VectorL10n.authenticationRegistrationUsernameFooterAvailable("@bob:matrix.org"),
                       "The footer message should display that the username is available.")
        XCTAssertFalse(context.viewState.isUsernameInvalid,
                       "The username should continue to be valid when it is available.")
        
        // When clearing the error.
        context.send(viewAction: .resetUsernameAvailability)
        
        // Wait for the action to spawn a Task on the main actor as the Context protocol doesn't support actors.
        await Task.yield()
        
        // Then the error should be hidden again.
        XCTAssertEqual(context.viewState.usernameAvailability, .unknown, "The username availability should return to an unknown state.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, VectorL10n.authenticationRegistrationUsernameFooter, "The standard footer message should be shown again.")
        XCTAssertFalse(context.viewState.isUsernameInvalid, "The username should be valid when an error is cleared.")
    }
    
    func testUsernameAvailabilityWhenChanged() async throws {
        // Given a form with an entered username.
        context.username = "robert"
        XCTAssertEqual(context.viewState.usernameAvailability, .unknown, "The username availability should be unknown when the view model is created.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, VectorL10n.authenticationRegistrationUsernameFooter, "The standard footer message should be shown.")
        XCTAssertFalse(context.viewState.isUsernameInvalid, "The username should be valid if there is no error.")
        
        // When updating the state for an available username that was previously entered.
        viewModel.confirmUsernameAvailability("bob")
        
        // Then the username should not be shown as available.
        XCTAssertEqual(context.viewState.usernameAvailability, .unknown, "The username availability should not be updated.")
        XCTAssertEqual(context.viewState.usernameFooterMessage, VectorL10n.authenticationRegistrationUsernameFooter, "The standard footer message should be shown.")
        XCTAssertFalse(context.viewState.isUsernameInvalid, "The username should continue to be valid when unverified.")
    }
    
    func testEmptyUsernameWithShortPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertTrue(context.viewState.isPasswordInvalid, "An empty password should be invalid.")
        XCTAssertTrue(context.viewState.isUsernameInvalid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a password of 7 characters without a username.
        context.username = ""
        context.password = "1234567"
        
        // Then the credentials should remain invalid.
        XCTAssertTrue(context.viewState.isPasswordInvalid, "A 7-character password should be invalid.")
        XCTAssertTrue(context.viewState.isUsernameInvalid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testEmptyUsernameWithValidPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertTrue(context.viewState.isPasswordInvalid, "An empty password should be invalid.")
        XCTAssertTrue(context.viewState.isUsernameInvalid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a password of 8 characters without a username.
        context.username = ""
        context.password = "12345678"
        
        // Then the password should be valid but the credentials should still be invalid.
        XCTAssertFalse(context.viewState.isPasswordInvalid, "An 8-character password should be valid.")
        XCTAssertTrue(context.viewState.isUsernameInvalid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testValidUsernameWithEmptyPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertTrue(context.viewState.isPasswordInvalid, "An empty password should be invalid.")
        XCTAssertTrue(context.viewState.isUsernameInvalid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a username without a password.
        context.username = "bob"
        context.password = ""
        
        // Then the username should be valid but the credentials should still be invalid.
        XCTAssertTrue(context.viewState.isPasswordInvalid, "An empty password should be invalid.")
        XCTAssertFalse(context.viewState.isUsernameInvalid, "The username should be valid when unverified.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testUsernameErrorWithValidPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertTrue(context.viewState.isPasswordInvalid, "An empty password should be invalid.")
        XCTAssertTrue(context.viewState.isUsernameInvalid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a username and password and encountering a username error
        context.username = "bob"
        context.password = "12345678"
        
        let errorMessage = "Username unavailable"
        viewModel.displayError(.usernameUnavailable(errorMessage))
        
        // Then the password should be valid but the credentials should still be invalid.
        XCTAssertFalse(context.viewState.isPasswordInvalid, "An 8-character password should be valid.")
        XCTAssertTrue(context.viewState.isUsernameInvalid, "The username should be invalid when an error is shown.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testValidCredentials() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertTrue(context.viewState.isPasswordInvalid, "An empty password should be invalid.")
        XCTAssertTrue(context.viewState.isUsernameInvalid, "An empty username should be invalid.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a username and an 8-character password.
        context.username = "bob"
        context.password = "12345678"
        
        // Then the credentials should be considered valid.
        XCTAssertFalse(context.viewState.isPasswordInvalid, "An 8-character password should be valid.")
        XCTAssertFalse(context.viewState.isUsernameInvalid, "The username should be valid when unverified.")
        XCTAssertTrue(context.viewState.hasValidCredentials, "The credentials should be valid when the username and password are valid.")
    }
    
    @MainActor func testLoadingServer() {
        // Given a form with valid credentials.
        context.username = "bob"
        context.password = "12345678"
        XCTAssertTrue(context.viewState.hasValidCredentials, "The credentials should be valid.")
        XCTAssertTrue(context.viewState.canSubmit, "The form should be valid to submit.")
        XCTAssertFalse(context.viewState.isLoading, "The view shouldn't start in a loading state.")
        
        // When updating the view model whilst loading a homeserver.
        viewModel.update(isLoading: true)
        
        // Then the view state should reflect that the homeserver is loading.
        XCTAssertTrue(context.viewState.isLoading, "The view should now be in a loading state.")
        XCTAssertFalse(context.viewState.canSubmit, "The form should be blocked from submission.")
        
        // When updating the view model after loading a homeserver.
        viewModel.update(isLoading: false)
        
        // Then the view state should reflect that the homeserver is now loaded.
        XCTAssertFalse(context.viewState.isLoading, "The view should be back in a loaded state.")
        XCTAssertTrue(context.viewState.canSubmit, "The form should once again be valid to submit.")
    }
    
    @MainActor func testUpdatingUsername() {
        // Given a form with valid credentials.
        let fullMXID = "@bob:example.com"
        context.username = fullMXID
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid without a password.")
        XCTAssertFalse(context.viewState.canSubmit, "The form not be ready to submit without a password.")
        XCTAssertFalse(context.viewState.isLoading, "The view shouldn't start in a loading state.")
        
        // When updating the view model with a new username.
        let localPart = "bob"
        viewModel.update(username: localPart)
        
        // Then the view state should reflect that the homeserver is loading.
        XCTAssertEqual(context.username, localPart, "The username should match the value passed to the update method.")
    }
}

extension AuthenticationRegistrationViewState.UsernameAvailability: Equatable {
    public static func == (lhs: AuthenticationRegistrationViewState.UsernameAvailability,
                           rhs: AuthenticationRegistrationViewState.UsernameAvailability) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.available, .available):
            return true
        case (.invalid, .invalid):
            return true
        default:
            return false
        }
    }
}
