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

@available(iOS 14.0, *)
struct OnboardingSplashScreenPage: View {
    
    // MARK: - Properties
    
    // MARK: Private
    @Environment(\.theme) private var theme
    
    // MARK: Public
    /// The content that this page should display.
    let content: OnboardingSplashScreenPageContent
    /// The height of the non-scrollable content in the splash screen.
    let overlayHeight: CGFloat
    
    // MARK: - Views
    
    @ViewBuilder
    var backgroundGradient: some View {
        if !theme.isDark {
            LinearGradient(gradient: content.gradient, startPoint: .leading, endPoint: .trailing)
                .flipsForRightToLeftLayoutDirection(true)
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                Image(theme.isDark ? content.darkImage.name : content.image.name)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .padding(20)
                    .accessibilityHidden(true)
                
                VStack(spacing: 8) {
                    OnboardingSplashScreenTitleText(content.title)
                        .font(theme.fonts.title2B)
                        .foregroundColor(theme.colors.primaryContent)
                    Text(content.message)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.secondaryContent)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom)
                
                Spacer()
                
                // Prevent the content from clashing with the overlay content.
                Spacer().frame(maxHeight: overlayHeight)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: OnboardingConstants.maxContentWidth,
                   maxHeight: OnboardingConstants.maxContentHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient.ignoresSafeArea())
    }
}

@available(iOS 14.0, *)
struct OnboardingSplashScreenPage_Previews: PreviewProvider {
    static let content = OnboardingSplashScreenViewState().content
    static var previews: some View {
        ForEach(0..<content.count, id:\.self) { index in
            OnboardingSplashScreenPage(content: content[index], overlayHeight: 200)
        }
    }
}
