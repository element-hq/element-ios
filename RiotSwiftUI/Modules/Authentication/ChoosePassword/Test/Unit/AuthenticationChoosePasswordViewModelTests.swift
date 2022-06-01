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
