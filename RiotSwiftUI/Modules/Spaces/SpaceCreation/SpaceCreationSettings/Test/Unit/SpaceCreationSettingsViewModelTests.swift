// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
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
