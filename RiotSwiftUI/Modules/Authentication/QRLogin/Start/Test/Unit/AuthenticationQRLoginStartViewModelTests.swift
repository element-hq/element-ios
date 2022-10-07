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
