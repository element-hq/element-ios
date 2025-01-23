//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationVerifyMsisdnViewModelTests: XCTestCase {
    var viewModel: AuthenticationVerifyMsisdnViewModelProtocol!
    var context: AuthenticationVerifyMsisdnViewModelType.Context!
    
    override func setUpWithError() throws {
        viewModel = AuthenticationVerifyMsisdnViewModel(homeserver: .mockMatrixDotOrg)
        context = viewModel.context
    }

    @MainActor func testSentSMSState() async {
        // Given a view model where the user hasn't yet sent the verification email.
        XCTAssertFalse(context.viewState.hasSentSMS, "The view model should start with hasSentSMS equal to false.")
        
        // When updating to indicate that an email has been send.
        viewModel.updateForSentSMS()
        
        // Then the view model should update to reflect a sent email.
        XCTAssertTrue(context.viewState.hasSentSMS, "The view model should update hasSentSMS after sending an email.")
    }

    @MainActor func testGoBack() async {
        viewModel.updateForSentSMS()

        context.otp = "123456"

        viewModel.goBackToMsisdnForm()

        XCTAssertFalse(context.viewState.hasSentSMS, "The view model should update hasSentSMS after going back.")
        XCTAssertTrue(context.viewState.hasInvalidOTP, "The view model should clear the OTP after going back.")
    }
}
