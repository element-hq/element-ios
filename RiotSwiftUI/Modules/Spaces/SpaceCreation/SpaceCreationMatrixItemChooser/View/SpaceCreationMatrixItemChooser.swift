//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct SpaceCreationMatrixItemChooser: View {
    // MARK: Properties
    
    @ObservedObject var viewModel: MatrixItemChooserViewModel.Context
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    // MARK: Public

    @ViewBuilder
    var body: some View {
        VStack {
            ThemableNavigationBar(title: nil, showBackButton: true) {
                viewModel.send(viewAction: .back)
            } closeAction: {
                viewModel.send(viewAction: .cancel)
            }
            mainView
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    // MARK: Private

    @ViewBuilder
    private var mainView: some View {
        ZStack(alignment: .bottom) {
            MatrixItemChooser(viewModel: viewModel, listBottomPadding: 72)
            footerView
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        ThemableButton(icon: nil, title: viewModel.viewState.selectedItemIds.isEmpty ? VectorL10n.skip : VectorL10n.next) {
            viewModel.send(viewAction: .done)
        }
        .accessibility(identifier: "doneButton")
        .padding(.horizontal, 24)
        .padding(.bottom)
    }
}
