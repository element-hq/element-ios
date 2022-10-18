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
