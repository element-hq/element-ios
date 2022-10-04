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
struct AuthenticationQRLoginScanScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var context: AuthenticationQRLoginScanViewModel.Context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                titleContent
                    .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                qrReaderView
            }
            .readableFrame()
        }
        .padding(.horizontal, 40)
        .background(theme.colors.background.ignoresSafeArea())
    }

    /// The screen's title and instructions.
    var titleContent: some View {
        VStack(spacing: 24) {
            Text(VectorL10n.authenticationQrLoginScanTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")

            Text(VectorL10n.authenticationQrLoginScanSubtitle)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.bottom, 24)
                .accessibilityIdentifier("subtitleLabel")
        }
    }

    @ViewBuilder
    var qrReaderView: some View {
        GeometryReader { geometry in
            VStack {
                switch context.viewState.serviceState {
                case .scanningQR:
                    if let scannerView = context.viewState.scannerView {
                        scannerView
                    }
                case .failed(let error):
                    switch error {
                    case .noCameraAccess:
                        Text(VectorL10n.cameraAccessNotGranted(AppInfo.current.displayName))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .font(theme.fonts.subheadline)
                            .foregroundColor(theme.colors.secondaryContent)

                        Button(action: goToSettings) {
                            Text(VectorL10n.settings)
                        }
                        .buttonStyle(SecondaryActionButtonStyle(font: theme.fonts.bodySB))
                        .padding(.horizontal)
                        .accessibilityIdentifier("openSettingsButton")
                    case .noCameraAvailable:
                        Text(VectorL10n.cameraUnavailable)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .font(theme.fonts.subheadline)
                            .foregroundColor(theme.colors.secondaryContent)
                    default:
                        EmptyView()
                    }
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: geometry.size.width)
            .background(theme.colors.quinaryContent)
        }
    }

    /// Sends the `goToSettings` view action.
    func goToSettings() {
        context.send(viewAction: .goToSettings)
    }
}

// MARK: - Previews

struct AuthenticationQRLoginScan_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationQRLoginScanScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light).preferredColorScheme(.light)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark).preferredColorScheme(.dark)
            .navigationViewStyle(.stack)
    }
}
