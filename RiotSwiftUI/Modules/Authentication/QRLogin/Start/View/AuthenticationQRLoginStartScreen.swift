//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The screen shown to a new user to select their use case for the app.
struct AuthenticationQRLoginStartScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @ScaledMetric private var iconSize = 70.0
    
    // MARK: Public
    
    @ObservedObject var context: AuthenticationQRLoginStartViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    titleContent
                        .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                    stepsView
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
                    .fill(theme.colors.accent)
                Image(Asset.Images.camera.name)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(14)
            }
            .frame(width: iconSize, height: iconSize)
            .padding(.bottom, 16)
            
            Text(VectorL10n.authenticationQrLoginStartTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")
            
            Text(VectorL10n.authenticationQrLoginStartSubtitle)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.bottom, 24)
                .accessibilityIdentifier("subtitleLabel")
        }
    }
    
    /// The screen's footer.
    var footerContent: some View {
        VStack(spacing: 12) {
            Button(action: scanQR) {
                Text(VectorL10n.authenticationQrLoginStartTitle)
            }
            .buttonStyle(PrimaryActionButtonStyle(font: theme.fonts.bodySB))
            .padding(.bottom, 8)
            .accessibilityIdentifier("scanQRButton")
            
            if context.viewState.canShowDisplayQRButton {
                LabelledDivider(label: VectorL10n.authenticationQrLoginStartNeedAlternative)
                
                Button(action: displayQR) {
                    Text(VectorL10n.authenticationQrLoginStartDisplayQr)
                }
                .buttonStyle(SecondaryActionButtonStyle(font: theme.fonts.bodySB))
                .accessibilityIdentifier("displayQRButton")
            }
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

    private let steps = [
        QRLoginStartStep(id: 1, description: VectorL10n.authenticationQrLoginStartStep1),
        QRLoginStartStep(id: 2, description: VectorL10n.authenticationQrLoginStartStep2),
        QRLoginStartStep(id: 3, description: VectorL10n.authenticationQrLoginStartStep3),
        QRLoginStartStep(id: 4, description: VectorL10n.authenticationQrLoginStartStep4)
    ]

    /// Sends the `scanQR` view action.
    func scanQR() {
        context.send(viewAction: .scanQR)
    }

    /// Sends the `displayQR` view action.
    func displayQR() {
        context.send(viewAction: .displayQR)
    }
}

// MARK: - Previews

struct AuthenticationQRLoginStart_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationQRLoginStartScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
            .navigationViewStyle(.stack)
    }
}

private struct QRLoginStartStep: Identifiable {
    let id: Int
    let description: String
}
