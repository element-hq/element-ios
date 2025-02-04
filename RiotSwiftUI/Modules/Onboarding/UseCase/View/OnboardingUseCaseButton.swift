//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
