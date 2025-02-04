// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationRooms SpaceCreationRooms
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class SpaceCreationRoomsViewModelTests: XCTestCase {
    var creationParameters = SpaceCreationParameters()
    var viewModel: SpaceCreationRoomsViewModelProtocol!
    var context: SpaceCreationRoomsViewModelType.Context!
    
    override func setUpWithError() throws {
        viewModel = SpaceCreationRoomsViewModel(creationParameters: creationParameters)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.title, creationParameters.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle)
        XCTAssertEqual(context.rooms, creationParameters.newRooms)
    }
}
