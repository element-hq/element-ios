//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

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
                ScrollView {
                    Spacer()
                        .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
                    
                    mainContent
                        .readableFrame()
                        .padding(.top, OnboardingMetrics.breakerScreenTopPadding)
                        .padding(.horizontal, horizontalPadding)
                }
                
                footer
                    .readableFrame()
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, OnboardingMetrics.actionButtonBottomPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                
                Spacer()
                    .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(effects.ignoresSafeArea())
        .background(theme.colors.accent.ignoresSafeArea())
        .navigationBarHidden(true)
        .preferredColorScheme(.dark) // make the status bar white
        .accentColor(.white)
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(spacing: OnboardingMetrics.breakerScreenIconBottomPadding) {
            Image(Asset.Images.onboardingCongratulationsIcon.name)
                .resizable()
                .scaledToFit()
                .frame(width: OnboardingMetrics.iconSize, height: OnboardingMetrics.iconSize)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text(VectorL10n.onboardingCongratulationsTitle)
                    .font(theme.fonts.title2B)
                    .foregroundColor(.white)
                
                StyledText(viewModel.viewState.messageString)
                    .font(theme.fonts.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    @ViewBuilder
    var footer: some View {
        if viewModel.viewState.personalizationDisabled {
            homeButton
        } else {
            actionButtons
        }
    }
    
    /// The default action buttons shown at the bottom of the view.
    var actionButtons: some View {
        VStack(spacing: 12) {
            Button { viewModel.send(viewAction: .personaliseProfile) } label: {
                Text(VectorL10n.onboardingCongratulationsPersonalizeButton)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.accent)
            }
            .buttonStyle(PrimaryActionButtonStyle(customColor: .white))
            .accessibilityIdentifier("personalizeButton")
            
            Button { viewModel.send(viewAction: .takeMeHome) } label: {
                Text(VectorL10n.onboardingCongratulationsHomeButton)
                    .font(theme.fonts.body)
                    .padding(.vertical, 12)
            }
            .accessibilityIdentifier("homeButton")
        }
    }
    
    /// The single "Take me home" button shown when personlization isn't supported.
    var homeButton: some View {
        Button { viewModel.send(viewAction: .takeMeHome) } label: {
            Text(VectorL10n.onboardingCongratulationsHomeButton)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.accent)
        }
        .buttonStyle(PrimaryActionButtonStyle(customColor: .white))
        .accessibilityIdentifier("homeButton")
    }
    
    var effects: some View {
        EffectsView(effect: .confetti)
            .allowsHitTesting(false)
    }
}

// MARK: - Previews

struct OnboardingCongratulationsScreen_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingCongratulationsScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
