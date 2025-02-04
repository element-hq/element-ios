//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The screen shown to a new user to select their use case for the app.
struct AuthenticationQRLoginFailureScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @ScaledMetric private var iconSize = 70.0
    
    // MARK: Public
    
    @ObservedObject var context: AuthenticationQRLoginFailureViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    titleContent
                        .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                }
                .readableFrame()

                footerContent
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 36)
            }
            .padding(.horizontal, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }

    /// The screen's title and instructions.
    var titleContent: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.colors.alert)
                Image(Asset.Images.exclamationCircle.name)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(15)
            }
            .frame(width: iconSize, height: iconSize)
            .padding(.bottom, 16)

            Text(VectorL10n.authenticationQrLoginFailureTitle)
                .font(theme.fonts.title3SB)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")

            if let failureText = context.viewState.failureText {
                Text(failureText)
                    .font(theme.fonts.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.colors.secondaryContent)
                    .accessibilityIdentifier("failureLabel")
            }
        }
    }

    /// The screen's footer.
    var footerContent: some View {
        VStack(spacing: 16) {
            if context.viewState.retryButtonVisible {
                Button(action: retry) {
                    Text(VectorL10n.authenticationQrLoginFailureRetry)
                }
                .buttonStyle(PrimaryActionButtonStyle(font: theme.fonts.bodySB))
                .accessibilityIdentifier("retryButton")
            }

            Button(action: cancel) {
                Text(VectorL10n.cancel)
            }
            .buttonStyle(SecondaryActionButtonStyle(font: theme.fonts.bodySB))
            .accessibilityIdentifier("cancelButton")
        }
    }

    /// Sends the `retry` view action.
    func retry() {
        context.send(viewAction: .retry)
    }

    /// Sends the `cancel` view action.
    func cancel() {
        context.send(viewAction: .cancel)
    }
}

// MARK: - Previews

struct AuthenticationQRLoginFailure_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationQRLoginFailureScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
            .navigationViewStyle(.stack)
    }
}
