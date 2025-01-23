//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationQRLoginFailureViewModelTests: XCTestCase {
    var viewModel: AuthenticationQRLoginFailureViewModelProtocol!
    var context: AuthenticationQRLoginFailureViewModelType.Context!

    override func setUpWithError() throws {
        viewModel = AuthenticationQRLoginFailureViewModel(qrLoginService: MockQRLoginService(withState: .failed(error: .requestTimedOut)))
        context = viewModel.context
    }

    func testRetry() {
        var result: AuthenticationQRLoginFailureViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .retry)

        XCTAssertEqual(result, .retry)
    }

    func testCancel() {
        var result: AuthenticationQRLoginFailureViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .cancel)

        XCTAssertEqual(result, .cancel)
    }
}
