//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class MatrixItemChooserViewModelTests: XCTestCase {
    var creationParameters = SpaceCreationParameters()
    var service: MockMatrixItemChooserService!
    var viewModel: MatrixItemChooserViewModelProtocol!
    var context: MatrixItemChooserViewModel.Context!
    
    override func setUpWithError() throws {
        service = MockMatrixItemChooserService(type: .room)
        viewModel = MatrixItemChooserViewModel.makeMatrixItemChooserViewModel(matrixItemChooserService: service, title: VectorL10n.spacesCreationAddRoomsTitle, detail: VectorL10n.spacesCreationAddRoomsMessage, selectionHeader: nil)
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.emptyListMessage, VectorL10n.spacesNoResultFoundTitle)
        XCTAssertEqual(context.viewState.title, VectorL10n.spacesCreationAddRoomsTitle)
        XCTAssertEqual(context.viewState.message, VectorL10n.spacesCreationAddRoomsMessage)
        XCTAssertEqual(context.viewState.sections, MockMatrixItemChooserService.mockSections)
        XCTAssertEqual(context.viewState.selectedItemIds.count, 0)
    }

    func testItemSelection() throws {
        XCTAssertEqual(context.viewState.selectedItemIds.count, 0)
        service.simulateSelectionForItem(at: IndexPath(row: 0, section: 0))
        XCTAssertEqual(context.viewState.selectedItemIds.count, 1)
        XCTAssertEqual(context.viewState.selectedItemIds.first, MockMatrixItemChooserService.mockSections[0].items[0].id)
    }
}
