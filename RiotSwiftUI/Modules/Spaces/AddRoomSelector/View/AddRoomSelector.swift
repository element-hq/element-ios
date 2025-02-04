//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct AddRoomSelector: View {
    // MARK: Properties
    
    @ObservedObject var viewModel: MatrixItemChooserViewModel.Context
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    private var isDoneEnabled: Bool {
        !viewModel.viewState.selectedItemIds.isEmpty && !viewModel.viewState.loading
    }

    // MARK: Setup
    
    var body: some View {
        MatrixItemChooser(viewModel: viewModel, listBottomPadding: nil)
            .background(theme.colors.background.ignoresSafeArea())
            .navigationBarItems(leading: cancelButton, trailing: doneButton)
            .accentColor(theme.colors.accent)
    }

    // MARK: Private
    
    private var cancelButton: some View {
        Button(VectorL10n.cancel, action: {
            viewModel.send(viewAction: .cancel)
        })
        .font(theme.fonts.body)
    }
    
    private var doneButton: some View {
        Button(VectorL10n.add, action: {
            viewModel.send(viewAction: .done)
        })
        .font(theme.fonts.body)
        .opacity(isDoneEnabled ? 1 : 0.7)
        .disabled(!isDoneEnabled)
    }
}
