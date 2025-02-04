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

class SpaceCreationMenuViewModelTests: XCTestCase {
    private enum Constants { }

    let navTitle = VectorL10n.spacesCreateSpaceTitle
    var creationParams = SpaceCreationParameters()
    let title = VectorL10n.spacesCreateSpaceTitle
    let detail = VectorL10n.spacesCreationVisibilityMessage
    let options = [
        SpaceCreationMenuRoomOption(id: .publicSpace, icon: Asset.Images.spaceTypeIcon.image, title: VectorL10n.spacePublicJoinRule, detail: VectorL10n.spacePublicJoinRuleDetail),
        SpaceCreationMenuRoomOption(id: .privateSpace, icon: Asset.Images.spacePrivateIcon.image, title: VectorL10n.spacePrivateJoinRule, detail: VectorL10n.spacePrivateJoinRuleDetail)
    ]

    var viewModel: SpaceCreationMenuViewModel!
    var context: SpaceCreationMenuViewModel.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        viewModel = SpaceCreationMenuViewModel(
            navTitle: navTitle,
            creationParams: creationParams,
            title: title,
            detail: detail,
            options: options
        )
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.navTitle, navTitle)
        XCTAssertEqual(context.viewState.title, title)
        XCTAssertEqual(context.viewState.detail, detail)
        XCTAssertEqual(context.viewState.options, options)
    }
}
