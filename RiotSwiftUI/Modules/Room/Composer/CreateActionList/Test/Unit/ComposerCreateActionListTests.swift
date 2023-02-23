//
// Copyright 2022 New Vector Ltd
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

@testable import RiotSwiftUI
import SwiftUI
import XCTest

class ComposerCreateActionListTests: XCTestCase {
    var viewModel: ComposerCreateActionListViewModel!
    var context: ComposerCreateActionListViewModel.Context!
    
    override func setUpWithError() throws {
        viewModel = ComposerCreateActionListViewModel(
            initialViewState: ComposerCreateActionListViewState(
                actions: ComposerCreateAction.allCases,
                wysiwygEnabled: true,
                isScrollingEnabled: false,
                bindings: ComposerCreateActionListBindings(textFormattingEnabled: true)
            )
        )
        context = viewModel.context
    }
    
    func testSelection() throws {
        let actionToSelect: ComposerCreateAction = .attachments
        var result: ComposerCreateActionListViewModelResult?
        viewModel.callback = { callbackResult in
            result = callbackResult
        }
        
        viewModel.context.send(viewAction: .selectAction(actionToSelect))

        XCTAssertEqual(result, .done(actionToSelect))
    }
}
