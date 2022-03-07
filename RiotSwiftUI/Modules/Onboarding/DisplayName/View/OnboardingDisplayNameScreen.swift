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
struct OnboardingDisplayNameScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var isEditingTextField = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingDisplayNameViewModel.Context
    
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
            .padding(.horizontal)
            .padding(.top, 8)
            .frame(maxHeight: .infinity)
        }
        .accentColor(theme.colors.accent)
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
    }
    
    /// The icon, title and message views.
    var header: some View {
        VStack(spacing: 8) {
            Image(Asset.Images.onboardingCongratulationsIcon.name)
                .renderingMode(.template)
                .foregroundColor(theme.colors.accent)
                .padding(.bottom, 8)
                .accessibilityHidden(true)
            
            Text(VectorL10n.onboardingDisplayNameTitle)
                .font(theme.fonts.title2B)
                .foregroundColor(theme.colors.primaryContent)
            
            Text(VectorL10n.onboardingDisplayNameMessage)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
    
    /// The text field used to enter the displayname along with a hint.
    var textField: some View {
        VStack(spacing: 4) {
            TextField(VectorL10n.onboardingDisplayNamePlaceholder, text: $viewModel.displayName) {
                isEditingTextField = $0
            }
            .textFieldStyle(BorderedInputFieldStyle(theme: _theme, isEditing: isEditingTextField))
            
            Text(VectorL10n.onboardingDisplayNameHint)
                .font(theme.fonts.caption2)
                .foregroundColor(theme.colors.tertiaryContent)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// The main action buttons in the form.
    var buttons: some View {
        VStack(spacing: 8) {
            Button(VectorL10n.onboardingDisplayNameSave) {
                viewModel.send(viewAction: .save)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(viewModel.displayName.isEmpty || viewModel.viewState.isWaiting)
            
            #warning("Use font/theme")
            Button { viewModel.send(viewAction: .skip) } label: {
                Text(VectorL10n.onboardingDisplayNameSkip)
                    .padding(12)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct OnboardingDisplayName_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingDisplayNameScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
    }
}
