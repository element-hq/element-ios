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

@available(iOS 14.0, *)
struct AuthenticationServerSelectionScreen: View {
    
    enum Constants {
        static let textFieldID = "textFieldID"
    }

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    /// The scroll view proxy can be stored here for use in other methods.
    @State private var scrollView: ScrollViewProxy?
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationServerSelectionViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ScrollViewReader { reader in
                    VStack(spacing: 0) {
                        header
                            .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                            .padding(.bottom, 36)
                        
                        serverForm
                        
                        Spacer()
                        
                        emsBanner
                            .padding(.vertical, 16)
                    }
                    .frame(maxWidth: OnboardingMetrics.maxContentWidth, minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .onAppear { scrollView = reader }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .background(theme.colors.background.ignoresSafeArea())
        .toolbar { toolbar }
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            Image(Asset.Images.authenticationServerSelectionIcon.name)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(theme.colors.accent)
                .frame(width: 90, height: 90)
                .background(Circle().foregroundColor(.white).padding(4))
                .padding(.bottom, 8)
                .accessibilityHidden(true)
            
            Text(VectorL10n.authenticationServerSelectionTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
            
            Text(VectorL10n.authenticationServerSelectionMessage)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
    
    /// The text field and confirm button where the user enters a server URL.
    var serverForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedBorderTextField(title: nil,
                                   placeHolder: VectorL10n.authenticationServerSelectionServerUrl,
                                   text: $viewModel.homeserverAddress,
                                   footerText: viewModel.viewState.footerMessage,
                                   isError: viewModel.viewState.isShowingFooterError,
                                   isFirstResponder: false,
                                   configuration: UIKitTextInputConfiguration(keyboardType: .URL,
                                                                              returnKeyType: .default,
                                                                              autocapitalizationType: .none,
                                                                              autocorrectionType: .no),
                                   onTextChanged: nil,
                                   onEditingChanged: textFieldEditingChangeHandler)
            .onChange(of: viewModel.homeserverAddress) { _ in viewModel.send(viewAction: .clearFooterError) }
            .id(Constants.textFieldID)
            .accessibilityIdentifier("addressTextField")
            
            Button { viewModel.send(viewAction: .confirm) } label: {
                Text(viewModel.viewState.buttonTitle)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(viewModel.viewState.hasValidationError)
            .accessibilityIdentifier("confirmButton")
        }
    }
    
    /// A banner shown beneath the server form with information about hosting your own server.
    var emsBanner: some View {
        VStack(spacing: 12) {
            Image(Asset.Images.authenticationServerSelectionEmsLogo.name)
                .padding(.top, 8)
                .accessibilityHidden(true)
            
            Text(VectorL10n.authenticationServerSelectionEmsTitle)
                .font(theme.fonts.title3SB)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
            
            VStack(spacing: 2) {
                Text(VectorL10n.authenticationServerSelectionEmsMessage)
                    .font(theme.fonts.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.colors.secondaryContent)
                Text(VectorL10n.authenticationServerSelectionEmsLink)
                    .font(theme.fonts.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.colors.primaryContent)
            }
            .padding(.bottom, 4)
            .accessibilityElement(children: .combine)
            
            Button { viewModel.send(viewAction: .getInTouch) } label: {
                Text(VectorL10n.authenticationServerSelectionEmsButton)
                    .font(theme.fonts.body)
            }
            .buttonStyle(PrimaryActionButtonStyle(customColor: theme.colors.ems))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 9).foregroundColor(theme.colors.system))
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if viewModel.viewState.hasModalPresentation {
                Button { viewModel.send(viewAction: .dismiss) } label: {
                    Text(VectorL10n.cancel)
                }
                .accessibilityLabel(VectorL10n.cancel)
                .accessibilityIdentifier("dismissButton")
            }
        }
    }
    
    /// Ensures the textfield is on screen when editing starts.
    ///
    /// This is required due to the `.ignoresSafeArea(.keyboard)` modifier which preserves
    /// the spacing between the Next button and the EMS banner when the keyboard appears.
    func textFieldEditingChangeHandler(isEditing: Bool) {
        guard isEditing else { return }
        withAnimation { scrollView?.scrollTo(Constants.textFieldID) }
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct AuthenticationServerSelection_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationServerSelectionScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
    }
}
