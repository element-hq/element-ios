//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateUserProfile: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: TemplateUserProfileViewModel.Context
    
    var body: some View {
        VStack {
            TemplateUserProfileHeader(
                avatar: viewModel.viewState.avatar,
                displayName: viewModel.viewState.displayName,
                presence: viewModel.viewState.presence
            )
            Divider()
            HStack {
                Text("Counter: \(viewModel.viewState.count)")
                    .font(theme.fonts.title2)
                    .foregroundColor(theme.colors.secondaryContent)
                Button("-") {
                    viewModel.send(viewAction: .decrementCount)
                }
                Button("+") {
                    viewModel.send(viewAction: .incrementCount)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .background(theme.colors.background)
        .frame(maxHeight: .infinity)
        .navigationTitle(viewModel.viewState.displayName ?? "")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(VectorL10n.done) {
                    viewModel.send(viewAction: .done)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(VectorL10n.cancel) {
                    viewModel.send(viewAction: .cancel)
                }
            }
        }
    }
}

// MARK: - Previews

struct TemplateUserProfile_Previews: PreviewProvider {
    static let stateRenderer = MockTemplateUserProfileScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
