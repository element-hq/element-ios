//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationSoftLogoutViewModelTests: XCTestCase {
    @MainActor func testInitialStateForMatrixOrg() async {
        let credentials = SoftLogoutCredentials(userId: "mock_user_id",
                                                homeserverName: "https://matrix.org",
                                                userDisplayName: "mock_username",
                                                deviceId: nil)
        let viewModel = AuthenticationSoftLogoutViewModel(credentials: credentials,
                                                          homeserver: .mockMatrixDotOrg,
                                                          keyBackupNeeded: true)
        let context = viewModel.context

        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssert(context.password.isEmpty, "The view model should start with an empty password.")
        XCTAssert(context.viewState.hasInvalidPassword, "The view model should start with an invalid password.")
        XCTAssert(context.viewState.showSSOButtons, "The view model should show SSO buttons for the given homeserver.")
        XCTAssert(context.viewState.showLoginForm, "The view model should show login form for the given homeserver.")
        XCTAssert(context.viewState.showRecoverEncryptionKeysMessage, "The view model should show recover encryption keys message.")
    }

    @MainActor func testInitialStateForNoSSO() async {
        let credentials = SoftLogoutCredentials(userId: "mock_user_id",
                                                homeserverName: "https://example.com",
                                                userDisplayName: "mock_username",
                                                deviceId: nil)
        let viewModel = AuthenticationSoftLogoutViewModel(credentials: credentials,
                                                          homeserver: .mockBasicServer,
                                                          keyBackupNeeded: false)
        let context = viewModel.context

        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssert(context.password.isEmpty, "The view model should start with an empty password.")
        XCTAssert(context.viewState.hasInvalidPassword, "The view model should start with an invalid password.")
        XCTAssertFalse(context.viewState.showSSOButtons, "The view model should not show SSO buttons for the given homeserver.")
        XCTAssert(context.viewState.showLoginForm, "The view model should show login form for the given homeserver.")
        XCTAssertFalse(context.viewState.showRecoverEncryptionKeysMessage, "The view model should not show recover encryption keys message.")
    }
}
