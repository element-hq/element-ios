//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserSessionDetails: View {
    private enum LayoutConstants {
        static let listItemHorizontalPadding: CGFloat = 20
        static let sectionVerticalPadding: CGFloat = 8
    }
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: UserSessionDetailsViewModel.Context
    
    var body: some View {
        List {
            ForEach(viewModel.viewState.sections) { section in
                SwiftUI.Section {
                    ForEach(section.items) { item in
                        UserSessionDetailsItem(viewData: item, horizontalPadding: LayoutConstants.listItemHorizontalPadding)
                            .listRowInsets(EdgeInsets())
                    }
                } header: {
                    Text(section.header)
                        .foregroundColor(theme.colors.secondaryContent)
                        .font(theme.fonts.footnote)
                        .padding([.leading, .trailing], LayoutConstants.listItemHorizontalPadding)
                        .padding(.top, 32)
                        .padding(.bottom, LayoutConstants.sectionVerticalPadding)
                } footer: {
                    if let footer = section.footer {
                        Text(footer)
                            .foregroundColor(theme.colors.secondaryContent)
                            .font(theme.fonts.footnote)
                            .padding([.leading, .trailing], LayoutConstants.listItemHorizontalPadding)
                            .padding(.top, LayoutConstants.sectionVerticalPadding)
                    }
                }
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.grouped)
        .listBackgroundColor(theme.colors.system)
        .navigationBarTitle(VectorL10n.userSessionDetailsTitle)
    }
}

// MARK: - Previews

struct UserSessionDetails_Previews: PreviewProvider {
    static let stateRenderer = MockUserSessionDetailsScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true).theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true).theme(.dark).preferredColorScheme(.dark)
    }
}
