//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
