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
struct OnboardingCongratulationsScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 16
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingCongratulationsViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                mainContent
                    .padding(.top, 60)
                    .padding(.horizontal, horizontalPadding)
                
                Spacer()
                
                buttons
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 24)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
            }
            .frame(maxWidth: OnboardingConstants.maxContentWidth,
                   maxHeight: OnboardingConstants.maxContentHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(theme.colors.accent.ignoresSafeArea())
        .accentColor(.white)
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)    // make the status bar white
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(spacing: 62) {
            Image(Asset.Images.onboardingCongratulationsIcon.name)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text(VectorL10n.onboardingCongratulationsTitle)
                    .font(theme.fonts.title2B)
                    .foregroundColor(.white)
                
                Text(VectorL10n.onboardingCongratulationsMessage(viewModel.viewState.userId))
                    .font(theme.fonts.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    /// The action buttons shown at the bottom of the view.
    var buttons: some View {
        VStack(spacing: 12) {
            Button { viewModel.send(viewAction: .personaliseProfile) } label: {
                Text(VectorL10n.onboardingCongratulationsPersonaliseButton)
                    .font(theme.fonts.bodySB)
                    .foregroundColor(theme.colors.accent)
            }
            .buttonStyle(PrimaryActionButtonStyle(customColor: .white))
            
            Button { viewModel.send(viewAction: .takeMeHome) } label: {
                Text(VectorL10n.onboardingCongratulationsHomeButton)
                    .font(theme.fonts.body)
                    .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct OnboardingCongratulationsScreen_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingCongratulationsScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
