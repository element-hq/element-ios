//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationForgotPasswordViewModelTests: XCTestCase {
    var viewModel: AuthenticationForgotPasswordViewModelProtocol!
    var context: AuthenticationForgotPasswordViewModelType.Context!
    
    override func setUpWithError() throws {
        viewModel = AuthenticationForgotPasswordViewModel(homeserver: .mockMatrixDotOrg)
        context = viewModel.context
    }

    @MainActor func testSentEmailState() async {
        // Given a view model where the user hasn't yet sent the email.
        XCTAssertFalse(context.viewState.hasSentEmail, "The view model should start with hasSentEmail equal to false.")
        
        // When updating to indicate that an email has been sent.
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
