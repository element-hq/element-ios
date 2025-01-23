//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
