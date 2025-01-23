//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateSimpleScreen: View {
    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 16
    }
    
    @ObservedObject var viewModel: TemplateSimpleScreenViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView(showsIndicators: false) {
                    mainContent
                        .padding(.top, 50)
                        .padding(.horizontal, horizontalPadding)
                }
                
                buttons
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
            }
        }
        .background(theme.colors.background.ignoresSafeArea())
        .accentColor(theme.colors.accent)
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(spacing: 36) {
            Text(viewModel.viewState.promptType.title)
                .font(theme.fonts.title1B)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("title")
            
            Image(viewModel.viewState.promptType.image.name)
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .foregroundColor(theme.colors.accent)
            
            HStack {
                Text("Counter: \(viewModel.viewState.count)")
                    .foregroundColor(theme.colors.primaryContent)
                
                Button("-") {
                    viewModel.send(viewAction: .decrementCount)
                }
                
                Button("+") {
                    viewModel.send(viewAction: .incrementCount)
                }
            }
            .font(theme.fonts.title3)
        }
    }
    
    /// The action buttons shown at the bottom of the view.
    var buttons: some View {
        VStack {
            Button { viewModel.send(viewAction: .accept) } label: {
                Text("Accept")
                    .font(theme.fonts.bodySB)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            
            Button { viewModel.send(viewAction: .cancel) } label: {
                Text("Cancel")
                    .font(theme.fonts.body)
                    .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Previews

struct TemplateSimpleScreen_Previews: PreviewProvider {
    static let stateRenderer = MockTemplateSimpleScreenScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
