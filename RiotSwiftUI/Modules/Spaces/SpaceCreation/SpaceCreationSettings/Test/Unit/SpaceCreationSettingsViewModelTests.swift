// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class SpaceCreationSettingsViewModelTests: XCTestCase {
    let creationParameters = SpaceCreationParameters()
    var service: MockSpaceCreationSettingsService!
    var viewModel: SpaceCreationSettingsViewModel!
    var context: SpaceCreationSettingsViewModel.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        creationParameters.name = "Fake"
        creationParameters.isPublic = true
        creationParameters.topic = "Some short description"
        creationParameters.userSelectedAvatar = Asset.Images.appSymbol.image

        service = MockSpaceCreationSettingsService()
        viewModel = SpaceCreationSettingsViewModel(spaceCreationSettingsService: service, creationParameters: creationParameters)
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.title, creationParameters.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle)
        XCTAssertEqual(context.viewState.isAddressValid, true)
        XCTAssertEqual(context.viewState.defaultAddress, "fake-uri")
        XCTAssertEqual(context.viewState.addressMessage, VectorL10n.spacesCreationAddressDefaultMessage("#fake-uri:fake-domain.org"))
        XCTAssertEqual(context.viewState.avatarImage, Asset.Images.appSymbol.image)
        XCTAssertEqual(context.roomName, creationParameters.name)
        XCTAssertEqual(context.topic, creationParameters.topic)
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
