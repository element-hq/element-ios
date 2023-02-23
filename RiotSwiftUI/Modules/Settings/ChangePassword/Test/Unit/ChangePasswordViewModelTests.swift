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
