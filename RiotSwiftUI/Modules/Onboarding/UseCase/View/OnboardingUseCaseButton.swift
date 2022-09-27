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

import SwiftUI

/// A button used for the Use Case selection.
struct OnboardingUseCaseButton: View {
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    /// The button's title.
    let title: String
    /// The button's image.
    let image: ImageAsset
    
    /// The button's action when tapped.
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(image.name)
                Text(title)
                    .font(theme.fonts.bodySB)
                    .foregroundColor(theme.colors.primaryContent)
            }
            .padding(16)
        }
        .buttonStyle(OnboardingButtonStyle())
    }
}

struct Previews_OnboardingUseCaseButton_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingUseCaseButton(title: VectorL10n.onboardingUseCaseWorkMessaging,
                                image: Asset.Images.onboardingUseCaseWork,
                                action: { })
            .padding(16)
    }
}
