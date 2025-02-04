//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct AuthenticationServerSelectionScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    @State private var isEditingTextField = false
    
    private var textFieldFooterColor: Color {
        viewModel.viewState.hasValidationError ? theme.colors.alert : theme.colors.tertiaryContent
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationServerSelectionViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { _ in
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                        .padding(.bottom, 36)
                    
                    serverForm
                }
                .readableFrame()
                .padding(.horizontal, 16)
            }
        }
        .background(theme.colors.background.ignoresSafeArea())
        .toolbar { toolbar }
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationServerSelectionIcon)
                .padding(.bottom, 8)
            
            Text(viewModel.viewState.headerTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("headerTitle")
            
            Text(viewModel.viewState.headerMessage)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .accessibilityIdentifier("headerMessage")
        }
    }
    
    /// The text field and confirm button where the user enters a server URL.
    var serverForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 8) {
                textField
                    .onSubmit(submit)
                
                if case let .message(errorMessage) = viewModel.viewState.footerError {
                    Text(errorMessage)
                        .font(theme.fonts.footnote)
                        .foregroundColor(textFieldFooterColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("textFieldFooter")
                }
            }
            
            sunsetBanners
            
            Button(action: submit) {
                Text(viewModel.viewState.buttonTitle)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(viewModel.viewState.hasValidationError)
            .accessibilityIdentifier("confirmButton")
        }
    }
    
    var textField: some View {
        TextField(VectorL10n.authenticationServerSelectionServerUrl, text: $viewModel.homeserverAddress) {
            isEditingTextField = $0
        }
        .keyboardType(.URL)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .textFieldStyle(BorderedInputFieldStyle(isEditing: isEditingTextField,
                                                isError: viewModel.viewState.isShowingFooterError))
        .onChange(of: viewModel.homeserverAddress) { _ in viewModel.send(viewAction: .clearFooterError) }
        .accessibilityIdentifier("addressTextField")
    }
    
    @ViewBuilder
    var sunsetBanners: some View {
        if viewModel.viewState.footerError == .sunsetBanner, let replacementApp = BuildSettings.replacementApp {
            VStack(spacing: 16) {
                SunsetOIDCRegistrationBanner(homeserverAddress: viewModel.homeserverAddress, 
                                             replacementApp: replacementApp)
                
                SunsetDownloadBanner(replacementApp: replacementApp) {
                    viewModel.send(viewAction: .downloadReplacementApp(replacementApp))
                }
            }
            .padding(.vertical, 4)
            .padding(.bottom, 16)
            .accessibilityIdentifier("sunsetBanners")
        }
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
    
    /// Sends the `confirm` view action so long as the text field input is valid.
    func submit() {
        guard !viewModel.viewState.hasValidationError else { return }
        viewModel.send(viewAction: .confirm)
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
