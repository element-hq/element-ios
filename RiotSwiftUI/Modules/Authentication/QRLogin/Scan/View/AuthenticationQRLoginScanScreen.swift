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
    @ScaledMetric private var iconSize = 70.0
    private let overlayBgColor = Color.black.opacity(0.4)
    
    // MARK: Public
    
    @ObservedObject var context: AuthenticationQRLoginScanViewModel.Context

    var body: some View {
        switch context.viewState.serviceState {
        case .scanningQR:
            scanningBody
        case .failed(let error):
            switch error {
            case .noCameraAvailable, .noCameraAccess:
                errorBody(for: error)
            default:
                EmptyView()
            }
        default:
            EmptyView()
        }
    }

    var scanningBody: some View {
        ZStack {
            if let scannerView = context.viewState.scannerView {
                scannerView
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
            }
            overlayView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    var overlayView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack {
                    Spacer()
                    scanningTitleContent
                        .padding(.horizontal, 40)
                    Spacer()
                        .frame(height: 16)
                }
                .frame(height: additionalViewHeight(in: geometry))
                .frame(maxWidth: .infinity)
                .background(overlayBgColor)

                HStack(spacing: 0) {
                    overlayBgColor
                        .frame(width: 40)
                    Spacer()
                    overlayBgColor
                        .frame(width: 40)
                }
                .frame(maxWidth: .infinity)

                overlayBgColor
                    .frame(height: additionalViewHeight(in: geometry))
            }
        }
        .ignoresSafeArea()
    }

    /// The screen's title and instructions.
    var scanningTitleContent: some View {
        VStack(spacing: 24) {
            Text(VectorL10n.authenticationQrLoginScanTitle)
                .font(theme.fonts.title1B)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .accessibilityIdentifier("titleLabel")

            Text(VectorL10n.authenticationQrLoginScanSubtitle)
                .font(theme.fonts.bodySB)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.bottom, 24)
                .accessibilityIdentifier("subtitleLabel")
        }
    }

    func errorBody(for error: QRLoginServiceError) -> some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    errorTitleContent(for: error)
                        .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                }
                .readableFrame()

                errorFooterContent(for: error)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 20 : 36)
            }
            .padding(.horizontal, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }

    /// The screen's title and instructions on error.
    func errorTitleContent(for error: QRLoginServiceError) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.colors.accent)
                Image(Asset.Images.camera.name)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(14)
            }
            .frame(width: iconSize, height: iconSize)
            .padding(.bottom, 16)

            Text(VectorL10n.authenticationQrLoginStartTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")

            Text(error == .noCameraAccess ? VectorL10n.cameraAccessNotGranted(AppInfo.current.displayName) : VectorL10n.cameraUnavailable)
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .padding(.bottom, 24)
                .accessibilityIdentifier("subtitleLabel")
        }
    }

    /// The screen's footer on error.
    func errorFooterContent(for error: QRLoginServiceError) -> some View {
        VStack(spacing: 12) {
            if error == .noCameraAccess {
                Button(action: goToSettings) {
                    Text(VectorL10n.settings)
                }
                .buttonStyle(PrimaryActionButtonStyle(font: theme.fonts.bodySB))
                .padding(.bottom, 8)
                .accessibilityIdentifier("openSettingsButton")
            }

            if context.viewState.canShowDisplayQRButton {
                LabelledDivider(label: VectorL10n.authenticationQrLoginStartNeedAlternative)

                Button(action: displayQR) {
                    Text(VectorL10n.authenticationQrLoginStartDisplayQr)
                }
                .buttonStyle(SecondaryActionButtonStyle(font: theme.fonts.bodySB))
                .accessibilityIdentifier("displayQRButton")
            }
        }
    }

    /// Sends the `goToSettings` view action.
    func goToSettings() {
        context.send(viewAction: .goToSettings)
    }

    /// Sends the `displayQR` view action.
    func displayQR() {
        context.send(viewAction: .displayQR)
    }

    func squareSize(in geometry: GeometryProxy) -> CGFloat {
        geometry.size.width - 80
    }

    func additionalViewHeight(in geometry: GeometryProxy) -> CGFloat {
        (geometry.size.height - squareSize(in: geometry)) / 2
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
