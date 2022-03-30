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
import SceneKit

@available(iOS 14.0, *)
struct OnboardingCelebrationScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 16
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingCelebrationViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView(showsIndicators: false) {
                    Spacer()
                        .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
                    
                    mainContent
                        .padding(.top, 106)
                        .padding(.horizontal, horizontalPadding)
                        .frame(maxWidth: OnboardingMetrics.maxContentWidth)
                }
                .frame(maxWidth: .infinity)
                
                buttons
                    .frame(maxWidth: OnboardingMetrics.maxContentWidth)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 24)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                
                Spacer()
                    .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(effects.ignoresSafeArea())
        .background(theme.colors.background.ignoresSafeArea())
        .accentColor(theme.colors.accent)
        .navigationBarHidden(true)
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(spacing: 8) {
            Image(Asset.Images.onboardingCelebrationIcon.name)
                .resizable()
                .scaledToFit()
                .frame(width: 90)
                .foregroundColor(theme.colors.accent)
                .background(Circle().foregroundColor(.white).padding(2))
                .padding(.bottom, 42)
                .accessibilityHidden(true)
            
            Text(VectorL10n.onboardingCelebrationTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
            
            Text(VectorL10n.onboardingCelebrationMessage)
                .font(theme.fonts.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
    
    /// The action buttons shown at the bottom of the view.
    var buttons: some View {
        VStack {
            Button { viewModel.send(viewAction: .complete) } label: {
                Text(VectorL10n.onboardingCelebrationButton)
                    .font(theme.fonts.body)
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
    }
    
    var effects: some View {
        EffectsView(effectsType: .confetti)
            .allowsHitTesting(false)
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct OnboardingCelebration_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingCelebrationScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
