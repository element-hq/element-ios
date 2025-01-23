//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct AuthenticationVerifyMsisdnScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationVerifyMsisdnViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { _ in
            VStack {
                ScrollView {
                    if viewModel.viewState.hasSentSMS {
                        AuthenticationVerifyMsisdnOTPForm(viewModel: viewModel)
                            .readableFrame()
                            .padding(.horizontal, 16)
                    } else {
                        AuthenticationVerifyMsisdnForm(viewModel: viewModel)
                            .readableFrame()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .background(theme.colors.background.ignoresSafeArea())
        .toolbar { toolbar }
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }

    /// A simple toolbar with a cancel button.
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(viewModel.viewState.hasSentSMS ? VectorL10n.back : VectorL10n.cancel) {
                if viewModel.viewState.hasSentSMS {
                    viewModel.send(viewAction: .goBack)
                } else {
                    viewModel.send(viewAction: .cancel)
                }
            }
            .accessibilityIdentifier("cancelButton")
        }
    }
}

// MARK: - Previews

struct AuthenticationVerifyMsisdnScreen_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationVerifyMsisdnScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
