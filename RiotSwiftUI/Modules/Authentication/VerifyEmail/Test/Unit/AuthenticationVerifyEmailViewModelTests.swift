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

class AuthenticationVerifyEmailViewModelTests: XCTestCase {

    var viewModel: AuthenticationVerifyEmailViewModelProtocol!
    var context: AuthenticationVerifyEmailViewModelType.Context!
    
    override func setUpWithError() throws {
        viewModel = AuthenticationVerifyEmailViewModel(homeserver: .mockMatrixDotOrg)
        context = viewModel.context
    }

    @MainActor func testSentEmailState() async {
        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssertFalse(context.viewState.hasSentEmail, "The view model should start with hasSentEmail equal to false.")
        
        // When updating to indicate that an email has been send.
        viewModel.updateForSentEmail()
        
        // Then the view model should update to reflect a sent email.
        XCTAssertTrue(context.viewState.hasSentEmail, "The view model should update hasSentEmail after sending an email.")
    }

    @MainActor func testGoBack() async {
        viewModel.updateForSentEmail()

        viewModel.goBackToEnterEmailForm()

        XCTAssertFalse(context.viewState.hasSentEmail, "The view model should update hasSentEmail after going back.")
    }
}
