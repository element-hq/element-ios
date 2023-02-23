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

class OnboardingAvatarViewModelTests: XCTestCase {
    private enum Constants {
        static let userId = "@user:matrix.org"
        static let displayName = "Alice"
        static let avatarColorCount = DefaultThemeSwiftUI().colors.namesAndAvatars.count
        static let avatarImage = Asset.Images.appSymbol.image
    }
    
    var viewModel: OnboardingAvatarViewModelProtocol!
    var context: OnboardingAvatarViewModelType.Context!
    
    override func setUpWithError() throws {
        viewModel = OnboardingAvatarViewModel(userId: Constants.userId,
                                              displayName: Constants.displayName,
                                              avatarColorCount: Constants.avatarColorCount)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.placeholderAvatarLetter, "A")
        XCTAssertNil(context.viewState.avatar)
        XCTAssertNil(context.viewState.bindings.alertInfo)
    }
    
    func testUpdatingAvatar() {
        // Given the default view model
        XCTAssertNil(context.viewState.avatar, "The default view state should not have an avatar.")
        
        // When updating the image
        viewModel.updateAvatarImage(with: Constants.avatarImage)
        
        // Then the view state should contain the new image
        XCTAssertEqual(context.viewState.avatar, Constants.avatarImage, "The view state should contain the new avatar image.")
    }
}
