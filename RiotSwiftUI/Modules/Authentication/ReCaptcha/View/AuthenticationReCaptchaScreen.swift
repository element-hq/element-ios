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
