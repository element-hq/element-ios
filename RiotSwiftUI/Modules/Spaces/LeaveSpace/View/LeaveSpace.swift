//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LeaveSpace: View {
    // MARK: Properties
    
    @ObservedObject var viewModel: MatrixItemChooserViewModel.Context
    let navTitle: String?
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ViewBuilder
    var body: some View {
        mainView
            .background(theme.colors.background.ignoresSafeArea())
    }
    
    // MARK: - Private

    @ViewBuilder
    private var mainView: some View {
        ZStack(alignment: .bottom) {
            MatrixItemChooser(viewModel: viewModel, listBottomPadding: 72)
            footerView
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        Button {
            viewModel.send(viewAction: .done)
        } label: {
            Text(viewModel.viewState.selectedItemIds.isEmpty ? VectorL10n.leaveSpaceAction : (viewModel.viewState.selectedItemIds.count == 1 ? VectorL10n.leaveSpaceAndOneRoom : VectorL10n.leaveSpaceAndMoreRooms("\(viewModel.viewState.selectedItemIds.count)")))
        }
        .buttonStyle(PrimaryActionButtonStyle(customColor: theme.colors.alert))
        .padding()
    }
}
