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

struct AuthenticationChoosePasswordScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme

    @State private var isEditingTextField = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationChoosePasswordViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                    .padding(.bottom, 36)
                form
            }
            .readableFrame()
            .padding(.horizontal, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }

    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationPasswordIcon)
                .padding(.bottom, 8)

            Text(VectorL10n.authenticationChoosePasswordInputTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")

            Text(VectorL10n.authenticationChoosePasswordInputMessage)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .accessibilityIdentifier("messageLabel")
        }
    }

    /// The text field and submit button where the user enters an email address.
    var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            textField

            HStack(alignment: .center, spacing: 8) {
                Toggle(VectorL10n.authenticationChoosePasswordSignoutAllDevices, isOn: $viewModel.signoutAllDevices)
                    .toggleStyle(AuthenticationTermsToggleStyle())
                    .accessibilityIdentifier("signoutAllDevicesToggle")
                Text(VectorL10n.authenticationChoosePasswordSignoutAllDevices)
                    .foregroundColor(theme.colors.secondaryContent)
            }
            .padding(.bottom, 16)
            .onTapGesture(perform: toggleSignoutAllDevices)

            Button(action: submit) {
                Text(VectorL10n.authenticationChoosePasswordSubmitButton)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(viewModel.viewState.hasInvalidPassword)
            .accessibilityIdentifier("submitButton")
        }
    }

    /// The text field, extracted for iOS 15 modifiers to be applied.
    var textField: some View {
        RoundedBorderTextField(placeHolder: VectorL10n.authenticationChoosePasswordTextFieldPlaceholder,
                               text: $viewModel.password,
                               isFirstResponder: isEditingTextField,
                               configuration: UIKitTextInputConfiguration(returnKeyType: .done,
                                                                          isSecureTextEntry: true),
                               onCommit: submit)
            .accessibilityIdentifier("passwordTextField")
    }

    /// Sends the `send` view action so long as a valid email address has been input.
    func submit() {
        guard !viewModel.viewState.hasInvalidPassword else { return }
        viewModel.send(viewAction: .submit)
    }

    /// Sends the `toggleSignoutAllDevices` view action.
    func toggleSignoutAllDevices() {
        viewModel.send(viewAction: .toggleSignoutAllDevices)
    }
}

// MARK: - Previews

struct AuthenticationChoosePasswordScreen_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationChoosePasswordScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
