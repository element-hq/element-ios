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

struct AuthenticationRegistrationScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var isPasswordFocused = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationRegistrationViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                    .padding(.bottom, 36)
                
                serverInfo
                    .padding(.leading, 12)
                
                Rectangle()
                    .fill(theme.colors.quinaryContent)
                    .frame(height: 1)
                    .padding(.vertical, 21)
                
                if viewModel.viewState.showRegistrationForm {
                    registrationForm
                }
                
                if viewModel.viewState.showRegistrationForm && viewModel.viewState.showSSOButtons {
                    Text(VectorL10n.or)
                        .foregroundColor(theme.colors.secondaryContent)
                        .padding(.top, 16)
                }
                
                if viewModel.viewState.showSSOButtons {
                    ssoButtons
                        .padding(.top, 16)
                }
                
            }
            .readableFrame()
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }
    
    /// The header containing the icon, title and message.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.onboardingCongratulationsIcon)
                .padding(.bottom, 8)
            
            Text(VectorL10n.authenticationRegistrationTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
            
            Text(VectorL10n.authenticationRegistrationMessage)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
    
    /// The sever information section that includes a button to select a different server.
    var serverInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(VectorL10n.authenticationRegistrationServerTitle)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.secondaryContent)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.viewState.homeserverAddress)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.primaryContent)
                    
                    if let serverDescription = viewModel.viewState.serverDescription {
                        Text(serverDescription)
                            .font(theme.fonts.caption1)
                            .foregroundColor(theme.colors.tertiaryContent)
                            .accessibilityIdentifier("serverDescriptionText")
                    }
                }
                
                Spacer()
                
                Button { viewModel.send(viewAction: .selectServer) } label: {
                    Text(VectorL10n.edit)
                        .font(theme.fonts.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.colors.accent))
                }
            }
        }
    }
    
    /// The form with text fields for username and password, along with a submit button.
    var registrationForm: some View {
        VStack(spacing: 21) {
            RoundedBorderTextField(title: nil,
                                   placeHolder: VectorL10n.authenticationRegistrationUsername,
                                   text: $viewModel.username,
                                   footerText: viewModel.viewState.usernameFooterMessage,
                                   isError: viewModel.viewState.hasEditedUsername && !viewModel.viewState.isUsernameValid,
                                   isFirstResponder: false,
                                   configuration: UIKitTextInputConfiguration(returnKeyType: .next,
                                                                              autocapitalizationType: .none,
                                                                              autocorrectionType: .no),
                                   onEditingChanged: usernameEditingChanged)
            .onChange(of: viewModel.username) { _ in viewModel.send(viewAction: .clearUsernameError) }
            .accessibilityIdentifier("usernameTextField")
            
            RoundedBorderTextField(title: nil,
                                   placeHolder: VectorL10n.authPasswordPlaceholder,
                                   text: $viewModel.password,
                                   footerText: VectorL10n.authenticationRegistrationPasswordFooter,
                                   isError: viewModel.viewState.hasEditedPassword && !viewModel.viewState.isPasswordValid,
                                   isFirstResponder: isPasswordFocused,
                                   configuration: UIKitTextInputConfiguration(returnKeyType: .done,
                                                                              isSecureTextEntry: true),
                                   onEditingChanged: passwordEditingChanged)
            .accessibilityIdentifier("passwordTextField")
            
            Button(action: submit) {
                Text(VectorL10n.next)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!viewModel.viewState.hasValidCredentials)
            .accessibilityIdentifier("nextButton")
        }
    }
    
    /// A list of SSO buttons that can be used for login.
    var ssoButtons: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.viewState.ssoIdentityProviders) { provider in
                AuthenticationSSOButton(provider: provider) {
                    viewModel.send(viewAction: .continueWithSSO(id: provider.id))
                }
                .accessibilityIdentifier("ssoButton")
            }
        }
    }
    
    /// Validates the username when the text field ends editing, and selects the password text field.
    func usernameEditingChanged(isEditing: Bool) {
        guard !isEditing, !viewModel.username.isEmpty else { return }
        
        viewModel.send(viewAction: .validateUsername)
        isPasswordFocused = true
    }
    
    /// Enables password validation the first time the user taps return, and sends the username and submits the form if possible.
    func passwordEditingChanged(isEditing: Bool) {
        guard !isEditing else { return }
        isPasswordFocused = false
        submit()
        
        guard !viewModel.viewState.hasEditedPassword else { return }
        viewModel.send(viewAction: .enablePasswordValidation)
    }
    
    /// Sends the `next` view action so long as valid credentials have been input.
    func submit() {
        guard viewModel.viewState.hasValidCredentials else { return }
        viewModel.send(viewAction: .next)
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct AuthenticationRegistration_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationRegistrationScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
    }
}
