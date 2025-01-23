// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class SpaceCreationEmailInvitesViewModelTests: XCTestCase {
    var creationParameters = SpaceCreationParameters()
    var service: MockSpaceCreationEmailInvitesService!
    var viewModel: SpaceCreationEmailInvitesViewModelProtocol!
    var context: SpaceCreationEmailInvitesViewModelType.Context!
    
    override func setUpWithError() throws {
        service = MockSpaceCreationEmailInvitesService(defaultValidation: true, isLoading: false)
        viewModel = SpaceCreationEmailInvitesViewModel(creationParameters: creationParameters, service: service)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.title, creationParameters.isPublic ? VectorL10n.spacesCreationPublicSpaceTitle : VectorL10n.spacesCreationPrivateSpaceTitle)
        XCTAssertEqual(context.emailInvites, creationParameters.emailInvites)
    }
}
