//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class SpaceSelectorViewModelTests: XCTestCase {
    var service: MockSpaceSelectorService!
    var viewModel: SpaceSelectorViewModelProtocol!
    var context: SpaceSelectorViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        service = MockSpaceSelectorService()
        viewModel = SpaceSelectorViewModel.makeViewModel(service: service, showCancel: true)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.selectedSpaceId, MockSpaceSelectorService.homeItem.id)
        XCTAssertEqual(context.viewState.items, MockSpaceSelectorService.defaultSpaceList)
        XCTAssertEqual(context.viewState.navigationTitle, VectorL10n.spaceSelectorTitle)
    }
}
