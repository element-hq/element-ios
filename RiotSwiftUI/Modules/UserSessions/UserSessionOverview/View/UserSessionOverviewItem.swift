//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserSessionOverviewItem: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let title: String
    var alignment: Alignment = .leading
    var showsChevron = false
    var isDestructive = false
    var onBackgroundTap: (() -> Void)?
    
    var body: some View {
        Button(action: { onBackgroundTap?() }) {
            VStack(spacing: 0) {
                SeparatorLine()
                HStack {
                    Text(title)
                        .font(theme.fonts.body)
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity, alignment: alignment)
                    
                    if showsChevron {
                        Image(Asset.Images.disclosureIcon.name)
                            .foregroundColor(theme.colors.tertiaryContent)
                    }
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 16)
                SeparatorLine()
            }
            .background(theme.colors.background)
        }
    }
    
    var textColor: Color {
        isDestructive ? theme.colors.alert : theme.colors.primaryContent
    }
}

struct UserSessionOverviewItem_Previews: PreviewProvider {
    static var buttons: some View {
        NavigationView {
            ScrollView {
                UserSessionOverviewItem(title: "Nav item", showsChevron: true)
                UserSessionOverviewItem(title: "Button")
                UserSessionOverviewItem(title: "Button", isDestructive: true)
            }
        }
    }
    
    static var previews: some View {
        Group {
            buttons.theme(.light).preferredColorScheme(.light)
            buttons.theme(.dark).preferredColorScheme(.dark)
        }
    }
}
