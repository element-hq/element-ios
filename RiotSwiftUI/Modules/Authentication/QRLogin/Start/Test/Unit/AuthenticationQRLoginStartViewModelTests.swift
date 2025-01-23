//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationQRLoginStartViewModelTests: XCTestCase {
    var viewModel: AuthenticationQRLoginStartViewModelProtocol!
    var context: AuthenticationQRLoginStartViewModelType.Context!

    override func setUpWithError() throws {
        viewModel = AuthenticationQRLoginStartViewModel(qrLoginService: MockQRLoginService())
        context = viewModel.context
    }

    func testDisplayQRButtonVisibility() {
        XCTAssertTrue(viewModel.context.viewState.canShowDisplayQRButton)
    }

    func testScanQR() {
        var result: AuthenticationQRLoginStartViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .scanQR)

        XCTAssertEqual(result, .scanQR)
    }

    func testDisplayQR() {
        var result: AuthenticationQRLoginStartViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .displayQR)

        XCTAssertEqual(result, .displayQR)
    }
}
