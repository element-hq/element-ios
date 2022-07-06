// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationRooms SpaceCreationRooms
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
