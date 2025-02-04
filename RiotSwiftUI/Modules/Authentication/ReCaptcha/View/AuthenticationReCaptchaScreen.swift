//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct AuthenticationReCaptchaScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    @State private var isLoading = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationReCaptchaViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 40) {
                    header
                        .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                        .padding(.horizontal, 16)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    recaptcha
                        .frame(minHeight: 500)
                }
                .readableFrame()
                .frame(minHeight: geometry.size.height)
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(theme.colors.background.ignoresSafeArea())
        .toolbar { toolbar }
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }
    
    /// The header containing the icon, title and message.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationRecaptchaIcon)
                .padding(.bottom, 8)
            
            Text(VectorL10n.authenticationRecaptchaTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
        }
    }
    
    /// The web view that shows the ReCaptcha to the user.
    var recaptcha: some View {
        AuthenticationRecaptchaWebView(siteKey: viewModel.viewState.siteKey,
                                       homeserverURL: viewModel.viewState.homeserverURL,
                                       isLoading: $isLoading) { response in
            viewModel.send(viewAction: .validate(response))
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

struct AuthenticationReCaptcha_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationReCaptchaScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
