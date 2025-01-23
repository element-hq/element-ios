//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The screen shown to a new user to select their use case for the app.
struct AuthenticationQRLoginLoadingScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var context: AuthenticationQRLoginLoadingViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    loadingText
                        .padding(.top, 60)
                    loader
                }
                .readableFrame()

                footerContent
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 36)
            }
            .padding(.horizontal, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }

    @ViewBuilder
    var loadingText: some View {
        if let code = context.viewState.loadingText {
            Text(code)
                .multilineTextAlignment(.center)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("loadingLabel")
        }
    }

    @ViewBuilder
    var loader: some View {
        ProgressView()
            .padding(.top, 64)
            .accessibilityIdentifier("loader")
    }

    /// The screen's footer.
    var footerContent: some View {
        VStack(spacing: 8) {
            Button(action: cancel) {
                Text(VectorL10n.cancel)
            }
            .buttonStyle(SecondaryActionButtonStyle(font: theme.fonts.bodySB))
            .accessibilityIdentifier("cancelButton")
        }
    }

    /// Sends the `cancel` view action.
    func cancel() {
        context.send(viewAction: .cancel)
    }
}

// MARK: - Previews

struct AuthenticationQRLoginLoading_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationQRLoginLoadingScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
            .navigationViewStyle(.stack)
    }
}
