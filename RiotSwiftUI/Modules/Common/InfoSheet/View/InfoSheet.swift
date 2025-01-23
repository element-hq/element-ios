// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        let padding: CGFloat = 16
        VStack(spacing: 24) {
            VStack(spacing: 18) {
                Text(viewModel.viewState.title)
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.colors.primaryContent)
                    .accessibilityIdentifier(viewModel.viewState.title)
                    .padding([.leading, .trailing], padding)
                
                Rectangle()
                    .foregroundColor(theme.colors.system)
                    .frame(height: 1)
                
                Text(viewModel.viewState.description)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryContent)
                    .accessibilityIdentifier(viewModel.viewState.description)
                    .padding([.leading, .trailing], padding)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
            
            Button {
                viewModel.viewState.action.action()
                viewModel.send(viewAction: .actionTriggered)
            }
            label: {
                Text(viewModel.viewState.action.text)
                    .font(theme.fonts.bodySB)
                    .foregroundColor(theme.colors.background)
                    .frame(height: 46)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(viewModel.viewState.action.text)
            }
            .background(theme.colors.accent)
            .cornerRadius(8)
            .padding([.leading, .trailing], padding)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .padding(.bottom, padding)
        .padding(.top, 32)
        .frame(maxWidth: .infinity)
        .background(theme.colors.background.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Previews

struct InfoSheet_Previews: PreviewProvider {
    static let stateRenderer = MockInfoSheetScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
