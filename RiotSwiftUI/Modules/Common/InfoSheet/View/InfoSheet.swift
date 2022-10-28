// 
// Copyright 2022 New Vector Ltd
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

struct InfoSheet: View {
    struct Action {
        let text: String
        let action: () -> Void
    }
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    private let viewModel: InfoSheetViewModel.Context
    
    init(viewModel: InfoSheetViewModel.Context) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.viewState.title)
                    .font(theme.fonts.calloutSB)
                    .foregroundColor(theme.colors.primaryContent)
                    .accessibilityIdentifier(viewModel.viewState.title)
                
                Text(viewModel.viewState.description)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.primaryContent)
                    .accessibilityIdentifier(viewModel.viewState.description)
            }
            
            Button {
                viewModel.viewState.action.action()
                viewModel.send(viewAction: .actionTriggered)
            }
            label: {
                Text(viewModel.viewState.action.text)
                    .font(theme.fonts.bodySB)
                    .foregroundColor(theme.colors.background)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(viewModel.viewState.action.text)
            }
            .background(theme.colors.accent)
            .cornerRadius(8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Previews

struct InfoSheet_Previews: PreviewProvider {
    static let stateRenderer = MockInfoSheetScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
