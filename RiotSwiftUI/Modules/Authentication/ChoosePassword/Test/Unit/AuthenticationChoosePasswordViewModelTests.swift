//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationChoosePasswordViewModelTests: XCTestCase {
    @MainActor func testInitialState() async {
        let viewModel = AuthenticationChoosePasswordViewModel()
        let context = viewModel.context

        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssert(context.password.isEmpty, "The view model should start with an empty password.")
        XCTAssert(context.viewState.hasInvalidPassword, "The view model should start with an invalid password.")
        XCTAssertFalse(context.signoutAllDevices, "The view model should start with sign out of all devices unchecked.")
    }
}
