//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct OnboardingDisplayNameScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var isEditingTextField = false
    
    private var textFieldFooterColor: Color {
        viewModel.viewState.validationErrorMessage == nil ? theme.colors.tertiaryContent : theme.colors.alert
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingDisplayNameViewModel.Context
    
    // MARK: - Views
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.bottom, 32)
                
                textField
                    .padding(.horizontal, 2)
                    .padding(.bottom, 20)
                
                buttons
            }
            .readableFrame()
            .padding(.horizontal)
            .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
        }
        .frame(maxHeight: .infinity)
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
        .onChange(of: viewModel.displayName) { _ in
            viewModel.send(viewAction: .validateDisplayName)
        }
    }
    
    /// The icon, title and message views.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.onboardingCongratulationsIcon)
                .padding(.bottom, 8)
            
            Text(VectorL10n.onboardingDisplayNameTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
        }
    }
    
    /// The text field used to enter the displayname along with a hint.
    var textField: some View {
        VStack(spacing: 4) {
            TextField(VectorL10n.onboardingDisplayNamePlaceholder, text: $viewModel.displayName) {
                isEditingTextField = $0
            }
            .autocapitalization(.words)
            .textFieldStyle(BorderedInputFieldStyle(isEditing: isEditingTextField,
                                                    isError: viewModel.viewState.validationErrorMessage != nil))
            
            Text(viewModel.viewState.textFieldFooterMessage)
                .font(theme.fonts.footnote)
                .foregroundColor(textFieldFooterColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("textFieldFooter")
        }
    }
    
    /// The main action buttons in the form.
    var buttons: some View {
        VStack(spacing: 8) {
            Button(VectorL10n.onboardingPersonalizationSave) {
                viewModel.send(viewAction: .save)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(viewModel.displayName.isEmpty || viewModel.viewState.validationErrorMessage != nil)
            .accessibilityIdentifier("saveButton")
            
            Button { viewModel.send(viewAction: .skip) } label: {
                Text(VectorL10n.onboardingPersonalizationSkip)
                    .font(theme.fonts.body)
                    .padding(12)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct OnboardingDisplayName_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingDisplayNameScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
