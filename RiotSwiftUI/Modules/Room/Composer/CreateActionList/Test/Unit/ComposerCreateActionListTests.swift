//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
