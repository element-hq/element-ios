//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationQRLoginConfirmViewModelTests: XCTestCase {
    var viewModel: AuthenticationQRLoginConfirmViewModelProtocol!
    var context: AuthenticationQRLoginConfirmViewModelType.Context!

    override func setUpWithError() throws {
        viewModel = AuthenticationQRLoginConfirmViewModel(qrLoginService: MockQRLoginService(withState: .waitingForConfirmation("28E-1B9-D0F-896")))
        context = viewModel.context
    }

    func testConfirm() {
        var result: AuthenticationQRLoginConfirmViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .confirm)

        XCTAssertEqual(result, .confirm)
    }

    func testCancel() {
        var result: AuthenticationQRLoginConfirmViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .cancel)

        XCTAssertEqual(result, .cancel)
    }
}
