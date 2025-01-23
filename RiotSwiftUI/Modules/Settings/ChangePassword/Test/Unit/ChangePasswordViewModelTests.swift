//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class ChangePasswordViewModelTests: XCTestCase {
    @MainActor func testEmptyState() async {
        let viewModel = ChangePasswordViewModel()
        let context = viewModel.context

        // Given an empty view model
        XCTAssert(context.oldPassword.isEmpty, "The view model should start with an empty old password.")
        XCTAssert(context.newPassword1.isEmpty, "The view model should start with an empty new password 1.")
        XCTAssert(context.newPassword2.isEmpty, "The view model should start with an empty new password 2.")
        XCTAssertFalse(context.viewState.canSubmit, "The view model should not be able to submit.")
        XCTAssertFalse(context.signoutAllDevices, "The view model should start with sign out of all devices unchecked.")
    }

    @MainActor func testValidState() async {
        let viewModel = ChangePasswordViewModel(oldPassword: "12345678",
                                                newPassword1: "87654321",
                                                newPassword2: "87654321",
                                                signoutAllDevices: true)
        let context = viewModel.context

        // Given a filled view model in valid state
        XCTAssertFalse(context.oldPassword.isEmpty, "The view model should start with an empty old password.")
        XCTAssertFalse(context.newPassword1.isEmpty, "The view model should start with an empty new password 1.")
        XCTAssertFalse(context.newPassword2.isEmpty, "The view model should start with an empty new password 2.")
        XCTAssertTrue(context.viewState.canSubmit, "The view model should be able to submit.")
        XCTAssertTrue(context.signoutAllDevices, "Sign out of all devices should be checked.")
    }
}
