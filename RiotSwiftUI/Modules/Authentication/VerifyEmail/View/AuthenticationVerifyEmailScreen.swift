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

struct AuthenticationVerifyEmailScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationVerifyEmailViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    mainContent
                        .readableFrame()
                        .padding(.horizontal, 16)
                }
                
                if viewModel.viewState.hasSentEmail {
                    waitingFooter
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 36)
                }
            }
        }
        .background(background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .toolbar { toolbar }
        .accentColor(theme.colors.accent)
    }
    
    @ViewBuilder
    var mainContent: some View {
        if viewModel.viewState.hasSentEmail {
            waitingHeader
                .padding(.top, OnboardingMetrics.breakerScreenTopPadding)
                .padding(.bottom, 36)
        } else {
            AuthenticationVerifyEmailForm(viewModel: viewModel)
        }
    }
    
    /// The instructions shown whilst waiting for the user to tap the link in the email.
    var waitingHeader: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationEmailIcon)
                .padding(.bottom, OnboardingMetrics.breakerScreenIconBottomPadding)
            
            OnboardingTintedFullStopText(VectorL10n.authenticationVerifyEmailWaitingTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("waitingTitleLabel")
            
            Text(VectorL10n.authenticationVerifyEmailWaitingMessage(viewModel.emailAddress))
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .accessibilityIdentifier("waitingMessageLabel")
        }
    }
    
    /// The footer shown whilst waiting for the user to tap the link in the email.
    var waitingFooter: some View {
        VStack(spacing: 14) {
            Text(VectorL10n.authenticationVerifyEmailWaitingHint)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
            
            Button { viewModel.send(viewAction: .resend) } label: {
                Text(VectorL10n.authenticationVerifyEmailWaitingButton)
                    .font(theme.fonts.body)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("resendButton")
        }
    }
    
    @ViewBuilder
    /// The view's background, which will show a gradient in light mode after sending the email.
    var background: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                theme.colors.background
                
                if viewModel.viewState.hasSentEmail && !theme.isDark {
                    gradient
                        .frame(height: geometry.size.height * 0.65)
                }
            }
        }
    }
    
    /// The background gradient shown after sending the email.
    var gradient: some View {
        LinearGradient(gradient: viewModel.viewState.gradient,
                       startPoint: .leading,
                       endPoint: .trailing)
            .opacity(0.3)
            .mask(LinearGradient(colors: [.white, .clear],
                                 startPoint: .top,
                                 endPoint: .bottom))
    }
    
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { viewModel.send(viewAction: .cancel) } label: {
                Image(systemName: "chevron.backward")
            }
            .accessibilityLabel(VectorL10n.close)
            .accessibilityIdentifier("cancelButton")
        }
    }
}

// MARK: - Previews

struct AuthenticationVerifyEmailScreen_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationVerifyEmailScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
