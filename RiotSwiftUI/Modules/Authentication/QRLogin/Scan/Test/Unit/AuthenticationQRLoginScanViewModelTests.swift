//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationQRLoginScanViewModelTests: XCTestCase {
    var viewModel: AuthenticationQRLoginScanViewModelProtocol!
    var context: AuthenticationQRLoginScanViewModelType.Context!

    override func setUpWithError() throws {
        viewModel = AuthenticationQRLoginScanViewModel(qrLoginService: MockQRLoginService())
        context = viewModel.context
    }

    func testDisplayQRButtonVisibility() {
        XCTAssertTrue(viewModel.context.viewState.canShowDisplayQRButton)
    }

    func testGoToSettings() {
        var result: AuthenticationQRLoginScanViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .goToSettings)

        XCTAssertEqual(result, .goToSettings)
    }

    func testDisplayQR() {
        var result: AuthenticationQRLoginScanViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .displayQR)

        XCTAssertEqual(result, .displayQR)
    }
}
