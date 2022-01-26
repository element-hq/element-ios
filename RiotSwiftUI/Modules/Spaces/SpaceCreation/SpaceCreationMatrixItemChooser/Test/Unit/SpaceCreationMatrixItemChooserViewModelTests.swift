// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationMatrixItemChooser SpaceCreationMatrixItemChooser
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
import Combine

@testable import RiotSwiftUI

@available(iOS 14.0, *)
class SpaceCreationMatrixItemChooserViewModelTests: XCTestCase {

    var creationParameters = SpaceCreationParameters()
    var service: MockSpaceCreationMatrixItemChooserService!
    var viewModel: SpaceCreationMatrixItemChooserViewModelProtocol!
    var context: SpaceCreationMatrixItemChooserViewModel.Context!
    
    override func setUpWithError() throws {
        service = MockSpaceCreationMatrixItemChooserService(type: .room)
        viewModel = SpaceCreationMatrixItemChooserViewModel.makeSpaceCreationMatrixItemChooserViewModel(spaceCreationMatrixItemChooserService: service, creationParams: creationParameters)
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.navTitle, creationParameters.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle)
        XCTAssertEqual(context.viewState.emptyListMessage, VectorL10n.spacesNoResultFoundTitle)
        XCTAssertEqual(context.viewState.title, VectorL10n.spacesCreationAddRoomsTitle)
        XCTAssertEqual(context.viewState.message, VectorL10n.spacesCreationAddRoomsMessage)
        XCTAssertEqual(context.viewState.items, MockSpaceCreationMatrixItemChooserService.mockItems)
        XCTAssertEqual(context.viewState.selectedItemIds.count, 0)
    }

    func testItemSelection() throws {
        XCTAssertEqual(context.viewState.selectedItemIds.count, 0)
        service.simulateSelectionForItem(at: 0)
        XCTAssertEqual(context.viewState.selectedItemIds.count, 1)
        XCTAssertEqual(context.viewState.selectedItemIds.first, MockSpaceCreationMatrixItemChooserService.mockItems[0].id)
    }
}
