//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
