//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationQRLoginDisplayViewModelTests: XCTestCase {
    var viewModel: AuthenticationQRLoginDisplayViewModelProtocol!
    var context: AuthenticationQRLoginDisplayViewModelType.Context!

    override func setUpWithError() throws {
        viewModel = AuthenticationQRLoginDisplayViewModel(qrLoginService: MockQRLoginService())
        context = viewModel.context
    }

    func testCancel() {
        var result: AuthenticationQRLoginDisplayViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .cancel)

        XCTAssertEqual(result, .cancel)
    }
}
