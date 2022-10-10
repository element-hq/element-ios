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

struct AuthenticationSoftLogoutScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationSoftLogoutViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                header
                if viewModel.viewState.showLoginForm {
                    loginForm
                } else if !viewModel.viewState.showSSOButtons {
                    fallbackButton
                }
                clearDataForm
                if viewModel.viewState.showSSOButtons {
                    Text(VectorL10n.or)
                        .foregroundColor(theme.colors.secondaryContent)
                        .accessibilityIdentifier("orLabel")
                    ssoButtons
                }
            }
            .readableFrame()
            .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
            .padding(.horizontal, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }

    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingIconImage(image: Asset.Images.authenticationPasswordIcon)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(VectorL10n.authSoftlogoutSignIn)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.leading)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")

            Text(VectorL10n.authSoftlogoutReason(viewModel.viewState.credentials.homeserverName, viewModel.viewState.credentials.userDisplayName, viewModel.viewState.credentials.userId))
                .font(theme.fonts.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("messageLabel1")

            if viewModel.viewState.showRecoverEncryptionKeysMessage {
                Text(VectorL10n.authSoftlogoutRecoverEncryptionKeys)
                    .font(theme.fonts.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(theme.colors.primaryContent)
                    .accessibilityIdentifier("messageLabel2")
            }
        }
    }

    /// The text field and submit button where the user enters an email address.
    var loginForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            passwordTextField

            Button(action: forgotPassword) {
                Text(VectorL10n.authenticationLoginForgotPassword)
                    .font(theme.fonts.body)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.bottom, 8)
            .accessibilityIdentifier("forgotPasswordButton")

            Button(action: login) {
                Text(VectorL10n.login)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(viewModel.viewState.hasInvalidPassword)
            .accessibilityIdentifier("loginButton")
        }
    }

    /// A fallback button that can be used for login.
    var fallbackButton: some View {
        Button(action: fallback) {
            Text(VectorL10n.login)
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .accessibilityIdentifier("fallbackButton")
    }

    /// The text field and submit button where the user enters an email address.
    var clearDataForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(VectorL10n.authSoftlogoutClearData)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.leading)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("clearDataTitleLabel")

            Text(VectorL10n.authSoftlogoutClearDataMessage1)
                .font(theme.fonts.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("clearDataMessage1Label")

            Text(VectorL10n.authSoftlogoutClearDataMessage2)
                .font(theme.fonts.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("clearDataMessage2Label")
                .padding(.bottom, 12)

            Button(action: clearData) {
                Text(VectorL10n.authSoftlogoutClearDataButton)
            }
            .buttonStyle(PrimaryActionButtonStyle(customColor: theme.colors.alert))
            .accessibilityIdentifier("clearDataButton")
        }
    }

    /// The text field, extracted for iOS 15 modifiers to be applied.
    var passwordTextField: some View {
        RoundedBorderTextField(placeHolder: VectorL10n.loginPasswordPlaceholder,
                               text: $viewModel.password,
                               configuration: UIKitTextInputConfiguration(returnKeyType: .done,
                                                                          isSecureTextEntry: true),
                               onCommit: login)
            .accessibilityIdentifier("passwordTextField")
    }

    /// A list of SSO buttons that can be used for login.
    var ssoButtons: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.viewState.homeserver.ssoIdentityProviders) { provider in
                AuthenticationSSOButton(provider: provider) {
                    viewModel.send(viewAction: .continueWithSSO(provider))
                }
                .accessibilityIdentifier("ssoButton")
            }
        }
    }

    /// Sends the `login` view action so long as a valid email address has been input.
    func login() {
        guard !viewModel.viewState.hasInvalidPassword else { return }
        viewModel.send(viewAction: .login)
    }

    /// Sends the `fallback` view action.
    func fallback() {
        viewModel.send(viewAction: .fallback)
    }

    /// Sends the `forgotPassword` view action.
    func forgotPassword() {
        viewModel.send(viewAction: .forgotPassword)
    }

    /// Sends the `clearAllData` view action.
    func clearData() {
        viewModel.send(viewAction: .clearAllData)
    }
}

// MARK: - Previews

struct AuthenticationSoftLogoutScreen_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationSoftLogoutScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
