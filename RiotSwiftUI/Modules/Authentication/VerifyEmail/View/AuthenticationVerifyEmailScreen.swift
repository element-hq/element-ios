//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct AuthenticationVerifyEmailScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationVerifyEmailViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    mainContent
                        .readableFrame()
                        .padding(.horizontal, 16)
                }
                
                if viewModel.viewState.hasSentEmail {
                    waitingFooter
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 36)
                }
            }
        }
        .background(background.ignoresSafeArea())
        .toolbar { toolbar }
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }
    
    @ViewBuilder
    var mainContent: some View {
        if viewModel.viewState.hasSentEmail {
            waitingContent
        } else {
            AuthenticationVerifyEmailForm(viewModel: viewModel)
        }
    }
    
    var waitingContent: some View {
        VStack(spacing: 36) {
            waitingHeader
                .padding(.top, OnboardingMetrics.breakerScreenTopPadding)
            
            ProgressView()
                .scaleEffect(1.3)
                .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.secondaryContent))
        }
    }
    
    /// The instructions shown whilst waiting for the user to tap the link in the email.
    var waitingHeader: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationEmailIcon)
                .padding(.bottom, OnboardingMetrics.breakerScreenIconBottomPadding)
            
            OnboardingTintedFullStopText(VectorL10n.authenticationVerifyEmailWaitingTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("waitingTitleLabel")
            
            Text(VectorL10n.authenticationVerifyEmailWaitingMessage(viewModel.emailAddress))
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .accessibilityIdentifier("waitingMessageLabel")
        }
    }
    
    /// The footer shown whilst waiting for the user to tap the link in the email.
    var waitingFooter: some View {
        VStack(spacing: 14) {
            Text(VectorL10n.authenticationVerifyEmailWaitingHint)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
            
            Button { viewModel.send(viewAction: .resend) } label: {
                Text(VectorL10n.authenticationVerifyEmailWaitingButton)
                    .font(theme.fonts.body)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("resendButton")
        }
    }
    
    @ViewBuilder
    /// The view's background, which will show a gradient in light mode after sending the email.
    var background: some View {
        OnboardingBreakerScreenBackground(viewModel.viewState.hasSentEmail)
    }

    /// A simple toolbar with a cancel button.
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(viewModel.viewState.hasSentEmail ? VectorL10n.back : VectorL10n.cancel) {
                if viewModel.viewState.hasSentEmail {
                    viewModel.send(viewAction: .goBack)
                } else {
                    viewModel.send(viewAction: .cancel)
                }
            }
            .accessibilityIdentifier("cancelButton")
        }
    }
}

// MARK: - Previews

struct AuthenticationVerifyEmailScreen_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationVerifyEmailScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
