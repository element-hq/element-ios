//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ThemableNavigationBar: View {
    // MARK: - Style
    
    // MARK: - Properties
    
    let title: String?
    let showBackButton: Bool
    let backAction: () -> Void
    let closeAction: () -> Void

    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ViewBuilder
    var body: some View {
        HStack {
            Button(action: { backAction() }) {
                Image(uiImage: Asset.Images.spacesModalBack.image)
                    .renderingMode(.template)
                    .foregroundColor(theme.colors.secondaryContent)
            }
            .isHidden(!showBackButton)
            Spacer()
            if let title = title {
                Text(title).font(theme.fonts.headline)
                    .foregroundColor(theme.colors.primaryContent)
            }
            Spacer()
            Button(action: { closeAction() }) {
                Image(uiImage: Asset.Images.spacesModalClose.image)
                    .renderingMode(.template)
                    .foregroundColor(theme.colors.secondaryContent)
            }
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(theme.colors.background)
    }
}

// MARK: - Previews

struct NavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: { }, closeAction: { })
            }
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: { }, closeAction: { }).theme(.dark)
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: { }, closeAction: { }).theme(.dark)
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: { }, closeAction: { }).theme(.dark)
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: { }, closeAction: { }).theme(.dark)
            }.preferredColorScheme(.dark)
        }
        .padding()
    }
}
