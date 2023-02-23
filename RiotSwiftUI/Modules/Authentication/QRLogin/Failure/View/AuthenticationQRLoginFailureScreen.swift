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

/// The screen shown to a new user to select their use case for the app.
struct AuthenticationQRLoginFailureScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @ScaledMetric private var iconSize = 70.0
    
    // MARK: Public
    
    @ObservedObject var context: AuthenticationQRLoginFailureViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    titleContent
                        .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                }
                .readableFrame()

                footerContent
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 36)
            }
            .padding(.horizontal, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }

    /// The screen's title and instructions.
    var titleContent: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.colors.alert)
                Image(Asset.Images.exclamationCircle.name)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(15)
            }
            .frame(width: iconSize, height: iconSize)
            .padding(.bottom, 16)

            Text(VectorL10n.authenticationQrLoginFailureTitle)
                .font(theme.fonts.title3SB)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")

            if let failureText = context.viewState.failureText {
                Text(failureText)
                    .font(theme.fonts.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.colors.secondaryContent)
                    .accessibilityIdentifier("failureLabel")
            }
        }
    }

    /// The screen's footer.
    var footerContent: some View {
        VStack(spacing: 16) {
            if context.viewState.retryButtonVisible {
                Button(action: retry) {
                    Text(VectorL10n.authenticationQrLoginFailureRetry)
                }
                .buttonStyle(PrimaryActionButtonStyle(font: theme.fonts.bodySB))
                .accessibilityIdentifier("retryButton")
            }

            Button(action: cancel) {
                Text(VectorL10n.cancel)
            }
            .buttonStyle(SecondaryActionButtonStyle(font: theme.fonts.bodySB))
            .accessibilityIdentifier("cancelButton")
        }
    }

    /// Sends the `retry` view action.
    func retry() {
        context.send(viewAction: .retry)
    }

    /// Sends the `cancel` view action.
    func cancel() {
        context.send(viewAction: .cancel)
    }
}

// MARK: - Previews

struct AuthenticationQRLoginFailure_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationQRLoginFailureScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
            .navigationViewStyle(.stack)
    }
}
