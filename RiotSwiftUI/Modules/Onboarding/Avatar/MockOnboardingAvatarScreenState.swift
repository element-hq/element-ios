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

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockOnboardingAvatarScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case placeholderAvatar(userId: String, displayName: String)
    case userSelectedAvatar(userId: String, displayName: String)
    
    /// The associated screen
    var screenType: Any.Type {
        OnboardingAvatarScreen.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockOnboardingAvatarScreenState] {
        let userId = "@example:matrix.org"
        let displayName = "Jane"
        
        return [
            .placeholderAvatar(userId: userId, displayName: displayName),
            .userSelectedAvatar(userId: userId, displayName: displayName)
        ]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView)  {
        let avatarColorCount = DefaultThemeSwiftUI().colors.namesAndAvatars.count
        let viewModel: OnboardingAvatarViewModel
        switch self {
        case .placeholderAvatar(let userId, let displayName):
            viewModel = OnboardingAvatarViewModel(userId: userId, displayName: displayName, avatarColorCount: avatarColorCount)
        case .userSelectedAvatar(let userId, let displayName):
            viewModel = OnboardingAvatarViewModel(userId: userId, displayName: displayName, avatarColorCount: avatarColorCount)
            viewModel.updateAvatarImage(with: Asset.Images.appSymbol.image)
        }
        
        return (
            [self, viewModel],
            AnyView(OnboardingAvatarScreen(viewModel: viewModel.context)
                .addDependency(MockAvatarService.example))
        )
    }
}

extension MockOnboardingAvatarScreenState: CustomStringConvertible {
    // Added to have different descriptions in the SwiftUI target's list.
    var description: String {
        switch self {
        case .placeholderAvatar:
            return "placeholderAvatar"
        case .userSelectedAvatar:
            return "userSelectedAvatar"
        }
    }
}
