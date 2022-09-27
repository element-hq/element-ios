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

struct AuthenticationTermsScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationTermsViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                header
                    .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                    .padding(.horizontal)
                
                termsList // No horizontal padding as the list should span edge-to-edge.
                
                button
                    .padding(.horizontal)
            }
            .readableFrame()
            .padding(.bottom, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .toolbar { toolbar }
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }
    
    /// The header containing the icon, title and message.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationTermsIcon)
                .padding(.bottom, 8)
            
            Text(VectorL10n.authenticationTermsTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
            
            Text(viewModel.viewState.headerMessage)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
        }
    }
    
    /// The list of polices to be accepted.
    var termsList: some View {
        LazyVStack(spacing: 0) {
            ForEach($viewModel.policies) { $policy in
                AuthenticationTermsListItem(policy: $policy) {
                    viewModel.send(viewAction: .showPolicy(policy))
                }
            }
        }
    }
    
    /// The action button shown below the list.
    var button: some View {
        VStack {
            Button { viewModel.send(viewAction: .next) } label: {
                Text(VectorL10n.next)
                    .font(theme.fonts.body)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!viewModel.viewState.hasAcceptedAllPolicies)
            .accessibilityIdentifier("nextButton")
        }
    }
    
    /// A simple toolbar with a cancel button.
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(VectorL10n.cancel) {
                viewModel.send(viewAction: .cancel)
            }
        }
    }
}

// MARK: - Previews

struct AuthenticationTerms_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationTermsScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
    }
}
