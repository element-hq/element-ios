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

/// The screen shown to a new user to select their use case for the app.
struct AuthenticationQRLoginConfirmScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @ScaledMetric private var iconSize = 70.0
    
    // MARK: Public
    
    @ObservedObject var context: AuthenticationQRLoginConfirmViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    titleContent
                        .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                    codeView
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
            Image(Asset.Images.authenticationQrloginConfirmIcon.name)
                .frame(width: iconSize, height: iconSize)
                .padding(.bottom, 16)
            
            Text(VectorL10n.authenticationQrLoginConfirmTitle)
                .font(theme.fonts.title3SB)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")
            
            Text(VectorL10n.authenticationQrLoginConfirmSubtitle)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.bottom, 24)
                .accessibilityIdentifier("subtitleLabel")
        }
    }

    @ViewBuilder
    var codeView: some View {
        if let code = context.viewState.confirmationCode {
            Text(code)
                .multilineTextAlignment(.center)
                .font(theme.fonts.title1)
                .foregroundColor(theme.colors.primaryContent)
                .padding(.top, 80)
                .accessibilityIdentifier("confirmationCodeLabel")
        }
    }

    /// The screen's footer.
    var footerContent: some View {
        VStack(spacing: 16) {
            Text(VectorL10n.authenticationQrLoginConfirmAlert)
                .padding(10)
                .multilineTextAlignment(.center)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.alert)
                .shapedBorder(color: theme.colors.alert, borderWidth: 1, shape: RoundedRectangle(cornerRadius: 8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)
                .accessibilityIdentifier("alertText")

//            Button(action: confirm) {
//                Text(VectorL10n.confirm)
//            }
//            .buttonStyle(PrimaryActionButtonStyle(font: theme.fonts.bodySB))
//            .accessibilityIdentifier("confirmButton")

            Button(action: cancel) {
                Text(VectorL10n.cancel)
            }
            .buttonStyle(SecondaryActionButtonStyle(font: theme.fonts.bodySB))
            .accessibilityIdentifier("cancelButton")
        }
    }

    /// Sends the `confirm` view action.
    func confirm() {
        context.send(viewAction: .confirm)
    }

    /// Sends the `cancel` view action.
    func cancel() {
        context.send(viewAction: .cancel)
    }
}

// MARK: - Previews

struct AuthenticationQRLoginConfirm_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationQRLoginConfirmScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
            .navigationViewStyle(.stack)
    }
}
