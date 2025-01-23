//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class TemplateSimpleScreenViewModelTests: XCTestCase {
    private enum Constants {
        static let counterInitialValue = 0
    }
    
    var viewModel: TemplateSimpleScreenViewModelProtocol!
    var context: TemplateSimpleScreenViewModelType.Context!
    
    override func setUpWithError() throws {
        viewModel = TemplateSimpleScreenViewModel(promptType: .regular, initialCount: Constants.counterInitialValue)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.count, Constants.counterInitialValue)
    }

    func testCounter() throws {
        context.send(viewAction: .incrementCount)
        XCTAssertEqual(context.viewState.count, 1)
        
        context.send(viewAction: .incrementCount)
        XCTAssertEqual(context.viewState.count, 2)
        
        context.send(viewAction: .decrementCount)
        XCTAssertEqual(context.viewState.count, 1)
    }
}
