//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The screen shown to a new user to select their use case for the app.
struct AuthenticationQRLoginDisplayScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var context: AuthenticationQRLoginDisplayViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    titleContent
                        .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                    stepsView
                    qrView
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
        VStack(spacing: 24) {
            Text(VectorL10n.authenticationQrLoginDisplayTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")
            
            Text(VectorL10n.authenticationQrLoginDisplaySubtitle)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.bottom, 24)
                .accessibilityIdentifier("subtitleLabel")
        }
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
    
    /// The buttons used to select a use case for the app.
    var stepsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(steps) { step in
                HStack {
                    Text(String(step.id))
                        .font(theme.fonts.caption2SB)
                        .foregroundColor(theme.colors.accent)
                        .padding(6)
                        .shapedBorder(color: theme.colors.accent, borderWidth: 1, shape: Circle())
                        .offset(x: 1, y: 0)
                    Text(step.description)
                        .foregroundColor(theme.colors.primaryContent)
                        .font(theme.fonts.subheadline)
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    var qrView: some View {
        if let qrImage = context.viewState.qrImage {
            VStack {
                Image(uiImage: qrImage)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(theme.colors.primaryContent)
                    .scaledToFit()
                    .accessibilityIdentifier("qrImageView")
            }
            .aspectRatio(1, contentMode: .fit)
            .shapedBorder(color: theme.colors.quinaryContent,
                          borderWidth: 1,
                          shape: RoundedRectangle(cornerRadius: 8))
            .padding(1)
            .padding(.top, 16)
        }
    }

    private let steps = [
        QRLoginDisplayStep(id: 1, description: VectorL10n.authenticationQrLoginDisplayStep1),
        QRLoginDisplayStep(id: 2, description: VectorL10n.authenticationQrLoginDisplayStep2)
    ]
    
    /// Sends the `cancel` view action.
    func cancel() {
        context.send(viewAction: .cancel)
    }
}

// MARK: - Previews

struct AuthenticationQRLoginDisplay_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationQRLoginDisplayScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
            .navigationViewStyle(.stack)
    }
}

private struct QRLoginDisplayStep: Identifiable {
    let id: Int
    let description: String
}
