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
