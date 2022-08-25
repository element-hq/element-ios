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

struct OnboardingSplashScreenPage: View {
    // MARK: - Properties
    
    // MARK: Private

    @Environment(\.theme) private var theme
    
    // MARK: Public

    /// The content that this page should display.
    let content: OnboardingSplashScreenPageContent
    
    // MARK: - Views
    
    var body: some View {
        VStack {
            Image(theme.isDark ? content.darkImage.name : content.image.name)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 310) // This value is problematic. 300 results in dropped frames
                // on iPhone 12/13 Mini. 305 the same on iPhone 12/13. As of
                // iOS 15, 310 seems fine on all supported screen widths 🤞.
                .padding(20)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                OnboardingTintedFullStopText(content.title)
                    .font(theme.fonts.title2B)
                    .foregroundColor(theme.colors.primaryContent)
                Text(content.message)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.secondaryContent)
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom)
        .padding(.horizontal, 16)
        .readableFrame()
    }
}

struct OnboardingSplashScreenPage_Previews: PreviewProvider {
    static let content = OnboardingSplashScreenViewState().content
    static var previews: some View {
        ForEach(0..<content.count, id: \.self) { index in
            OnboardingSplashScreenPage(content: content[index])
        }
    }
}
