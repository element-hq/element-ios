//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct OnboardingBreakerScreenBackground: View {
    @Environment(\.theme) private var theme

    /// Flag indicating whether the gradient enabled on light theme
    var isGradientEnabled: Bool

    enum Constants {
        static let gradientColors = [
            Color(red: 0.646, green: 0.95, blue: 0.879),
            Color(red: 0.576, green: 0.929, blue: 0.961),
            Color(red: 0.874, green: 0.82, blue: 1)
        ]
    }

    /// The background gradient used with light mode.
    let gradient = Gradient(colors: Constants.gradientColors)

    init(_ isGradientEnabled: Bool = true) {
        self.isGradientEnabled = isGradientEnabled
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                theme.colors.background

                if isGradientEnabled, !theme.isDark {
                    LinearGradient(gradient: gradient,
                                   startPoint: .leading,
                                   endPoint: .trailing)
                        .opacity(0.3)
                        .mask(LinearGradient(colors: [.white, .clear],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .frame(height: geometry.size.height * 0.65)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Previews

struct OnboardingBreakerScreenBackground_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingBreakerScreenBackground()
            OnboardingBreakerScreenBackground()
                .theme(.dark).preferredColorScheme(.dark)
        }
    }
}
