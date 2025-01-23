//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationQRLoginLoadingViewModelTests: XCTestCase {
    var viewModel: AuthenticationQRLoginLoadingViewModelProtocol!
    var context: AuthenticationQRLoginLoadingViewModelType.Context!

    override func setUpWithError() throws {
        viewModel = AuthenticationQRLoginLoadingViewModel(qrLoginService: MockQRLoginService(withState: .connectingToDevice))
        context = viewModel.context
    }

    func testCancel() {
        var result: AuthenticationQRLoginLoadingViewModelResult?

        viewModel.callback = { callbackResult in
            result = callbackResult
        }

        context.send(viewAction: .cancel)

        XCTAssertEqual(result, .cancel)
    }
}
