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

import Combine
import XCTest

@testable import RiotSwiftUI

class SpaceSettingsViewModelTests: XCTestCase {
    let creationParameters = SpaceCreationParameters()
    var service: MockSpaceSettingsService!
    var viewModel: SpaceSettingsViewModelProtocol!
    var context: SpaceSettingsViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        let roomProperties = SpaceSettingsRoomProperties(
            name: "Space Name",
            topic: "Sapce topic",
            address: "#fake:matrix.org",
            avatarUrl: nil,
            visibility: .public,
            allowedParentIds: [],
            isAvatarEditable: true,
            isNameEditable: true,
            isTopicEditable: true,
            isAddressEditable: true,
            isAccessEditable: true
        )

        service = MockSpaceSettingsService(roomProperties: roomProperties, displayName: roomProperties.name, isLoading: false, showPostProcessAlert: false)
        viewModel = SpaceSettingsViewModel.makeSpaceSettingsViewModel(service: service)
        context = viewModel.context
    }
    
    func testAddressAlready() throws {
        service.simulateUpdate(addressValidationStatus: .alreadyExists("#fake:matrix.org"))
        XCTAssertEqual(context.viewState.isAddressValid, false)
        XCTAssertEqual(context.viewState.addressMessage, VectorL10n.spacesCreationAddressAlreadyExists("#fake:matrix.org"))
    }
    
    func testInvalidAddress() throws {
        service.simulateUpdate(addressValidationStatus: .invalidCharacters("#fake:matrix.org"))
        XCTAssertEqual(context.viewState.isAddressValid, false)
        XCTAssertEqual(context.viewState.addressMessage, VectorL10n.spacesCreationAddressInvalidCharacters("#fake:matrix.org"))
    }
}
