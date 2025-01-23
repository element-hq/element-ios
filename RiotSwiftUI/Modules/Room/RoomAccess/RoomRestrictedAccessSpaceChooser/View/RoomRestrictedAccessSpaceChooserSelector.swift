//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomRestrictedAccessSpaceChooserSelector: View {
    // MARK: Properties
    
    @ObservedObject var viewModel: MatrixItemChooserViewModel.Context
    let navTitle: String?
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    @ViewBuilder
    var body: some View {
        MatrixItemChooser(viewModel: viewModel, listBottomPadding: nil)
            .background(theme.colors.background)
            .navigationTitle(VectorL10n.roomAccessSettingsScreenNavTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(VectorL10n.cancel) {
                        viewModel.send(viewAction: .cancel)
                    }
                    .foregroundColor(viewModel.viewState.loading ? theme.colors.quarterlyContent : theme.colors.accent)
                    .opacity(viewModel.viewState.loading ? 0.7 : 1)
                    .disabled(viewModel.viewState.loading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(VectorL10n.done) {
                        viewModel.send(viewAction: .done)
                    }
                    .foregroundColor(viewModel.viewState.selectedItemIds.isEmpty || viewModel.viewState.loading ? theme.colors.quarterlyContent : theme.colors.accent)
                    .opacity(viewModel.viewState.selectedItemIds.isEmpty || viewModel.viewState.loading ? 0.7 : 1)
                    .disabled(viewModel.viewState.selectedItemIds.isEmpty || viewModel.viewState.loading)
                }
            }
    }
}
