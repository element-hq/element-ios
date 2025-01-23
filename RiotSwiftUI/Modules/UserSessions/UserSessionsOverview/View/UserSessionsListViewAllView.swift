//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserSessionsListViewAllView: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI

    let count: Int
    
    var onBackgroundTap: (() -> Void)?
    
    var body: some View {
        Button {
            onBackgroundTap?()
        } label: {
            Button(action: { onBackgroundTap?() }) {
                VStack(spacing: 0) {
                    HStack {
                        Text("View all (\(count))")
                            .font(theme.fonts.body)
                            .foregroundColor(theme.colors.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(Asset.Images.disclosureIcon.name)
                            .foregroundColor(theme.colors.tertiaryContent)
                    }
                    .padding(.vertical, 15)
                    .padding(.trailing, 20)
                }
                .background(theme.colors.background)
                .padding(.leading, 72)
            }
        }
        .accessibilityIdentifier("ViewAllButton")
    }
}

struct UserSessionsListViewAllView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserSessionsListViewAllView(count: 8)
                .previewLayout(PreviewLayout.sizeThatFits)
                .theme(.light)
                .preferredColorScheme(.light)
            
            UserSessionsListViewAllView(count: 8)
                .previewLayout(PreviewLayout.sizeThatFits)
                .theme(.dark)
                .preferredColorScheme(.dark)
        }
    }
}
