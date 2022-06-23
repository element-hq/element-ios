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

struct AddRoomSelector: View {
    
    // MARK: Properties
    
    @ObservedObject var viewModel: MatrixItemChooserViewModel.Context
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    private var isDoneEnabled: Bool {
        return !viewModel.viewState.selectedItemIds.isEmpty && !viewModel.viewState.loading
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
