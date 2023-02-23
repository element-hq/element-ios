//
// Copyright 2022 New Vector Ltd
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
