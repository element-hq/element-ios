//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct OnboardingIconImage: View {
    @Environment(\.theme) private var theme
    
    let image: ImageAsset
    
    var body: some View {
        Image(image.name)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(theme.colors.accent)
            .frame(width: OnboardingMetrics.iconSize, height: OnboardingMetrics.iconSize)
            .background(Circle().foregroundColor(.white).padding(2))
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

struct OnboardingIconImage_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingIconImage(image: Asset.Images.authenticationEmailIcon)
    }
}
