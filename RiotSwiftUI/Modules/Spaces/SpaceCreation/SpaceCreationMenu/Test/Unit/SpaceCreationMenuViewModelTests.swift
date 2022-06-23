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

import XCTest
import Combine

@testable import RiotSwiftUI

class SpaceCreationMenuViewModelTests: XCTestCase {
    private enum Constants {
    }

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
