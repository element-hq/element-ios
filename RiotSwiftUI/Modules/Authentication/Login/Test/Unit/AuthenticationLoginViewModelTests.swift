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

@testable import RiotSwiftUI

class AuthenticationLoginViewModelTests: XCTestCase {
    let defaultHomeserver = AuthenticationHomeserverViewData.mockMatrixDotOrg
    var viewModel: AuthenticationLoginViewModelProtocol!
    var context: AuthenticationLoginViewModelType.Context!
    
    @MainActor override func setUp() async throws {
        viewModel = AuthenticationLoginViewModel(homeserver: defaultHomeserver)
        context = viewModel.context
    }
    
    func testMatrixDotOrg() {
        // Given the initial view model configured for matrix.org with some SSO providers.
        let homeserver = defaultHomeserver
        
        // Then the view state should contain a homeserver that matches matrix.org and shows SSO buttons.
        XCTAssertEqual(context.viewState.homeserver, homeserver, "The homeserver data should match the original.")
        XCTAssertTrue(context.viewState.showSSOButtons, "The SSO buttons should be shown.")
    }
    
    @MainActor func testBasicServer() {
        // Given a basic server example.com that only supports password registration.
        let homeserver = AuthenticationHomeserverViewData.mockBasicServer
        
        // When updating the view model with the server.
        viewModel.update(homeserver: homeserver)
        
        // Then the view state should be updated with the homeserver and hide the SSO buttons.
        XCTAssertEqual(context.viewState.homeserver, homeserver, "The homeserver data should should match the new homeserver.")
        XCTAssertFalse(context.viewState.showSSOButtons, "The SSO buttons should not be shown.")
    }
    
    func testUsernameWithEmptyPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a username without a password.
        context.username = "bob"
        context.password = ""
        
        // Then the credentials should be considered invalid.
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testEmptyUsernameWithPassword() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a password without a username.
        context.username = ""
        context.password = "12345678"
        
        // Then the credentials should be considered invalid.
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
    }
    
    func testValidCredentials() {
        // Given a form with an empty username and password.
        XCTAssertTrue(context.password.isEmpty, "The initial value for the password should be empty.")
        XCTAssertTrue(context.username.isEmpty, "The initial value for the username should be empty.")
        XCTAssertFalse(context.viewState.hasValidCredentials, "The credentials should be invalid.")
        
        // When entering a username and an 8-character password.
        context.username = "bob"
        context.password = "12345678"
        
        // Then the credentials should be considered valid.
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

    @MainActor func testFallbackServer() {
        // Given a basic server example.com that only supports password registration.
        let homeserver = AuthenticationHomeserverViewData.mockFallback

        // When updating the view model with the server.
        viewModel.update(homeserver: homeserver)

        // Then the view state should be updated with the homeserver and hide the SSO buttons and login form.
        XCTAssertFalse(context.viewState.showSSOButtons, "The SSO buttons should not be shown.")
        XCTAssertFalse(context.viewState.homeserver.showLoginForm, "The login form should not be shown.")
    }
}
