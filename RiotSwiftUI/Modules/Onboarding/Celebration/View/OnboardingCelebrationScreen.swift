//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SceneKit
import SwiftUI

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
                ScrollView {
                    Spacer()
                        .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
                    
                    mainContent
                        .readableFrame()
                        .padding(.top, OnboardingMetrics.breakerScreenTopPadding)
                        .padding(.horizontal, horizontalPadding)
                }
                
                buttons
                    .readableFrame()
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, OnboardingMetrics.actionButtonBottomPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                
                Spacer()
                    .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
            }
            .frame(maxHeight: .infinity)
        }
        .background(OnboardingBreakerScreenBackground().ignoresSafeArea())
        .accentColor(theme.colors.accent)
        .navigationBarHidden(true)
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.onboardingCelebrationIcon)
                .padding(.bottom, OnboardingMetrics.breakerScreenIconBottomPadding)
            
            Text(VectorL10n.onboardingCelebrationTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
            
            Text(VectorL10n.onboardingCelebrationMessage)
                .font(theme.fonts.body)
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
}

// MARK: - Previews

@available(iOS 15.0, *)
struct OnboardingCelebration_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingCelebrationScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
