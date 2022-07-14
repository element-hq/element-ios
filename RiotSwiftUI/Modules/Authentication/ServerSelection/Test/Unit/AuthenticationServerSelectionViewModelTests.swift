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

class AuthenticationServerSelectionViewModelTests: XCTestCase {
    private enum Constants {
        static let counterInitialValue = 0
    }
    
    var viewModel: AuthenticationServerSelectionViewModelProtocol!
    var context: AuthenticationServerSelectionViewModelType.Context!
    
    override func setUp() {
        viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: "", flow: .login, hasModalPresentation: true)
        context = viewModel.context
    }

    @MainActor func testErrorMessage() async throws {
        // Given a new instance of the view model.
        XCTAssertNil(context.viewState.footerErrorMessage, "There should not be an error message for a new view model.")
        XCTAssertFalse(context.viewState.isShowingFooterError, "There should not be an error shown.")
        
        // When an error occurs.
        let message = "Unable to contact server."
        viewModel.displayError(.footerMessage(message))
        
        // Then the footer should now be showing an error.
        XCTAssertEqual(context.viewState.footerErrorMessage, message, "The error message should be stored.")
        XCTAssertTrue(context.viewState.isShowingFooterError, "There should be an error shown.")
        
        // And when clearing the error.
        context.send(viewAction: .clearFooterError)
        
        // Wait for the action to spawn a Task on the main actor as the Context protocol doesn't support actors.
        await Task.yield()
        
        // Then the error message should now be removed.
        XCTAssertNil(context.viewState.footerErrorMessage, "The error message should have been cleared.")
        XCTAssertFalse(context.viewState.isShowingFooterError, "There should not be an error shown anymore.")
    }
}
