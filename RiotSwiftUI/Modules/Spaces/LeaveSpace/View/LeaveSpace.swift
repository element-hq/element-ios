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
