//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct MatrixItemChooserSectionHeader: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let title: String?
    let infoText: String?
    
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let titleText = title {
                Text(titleText)
                    .foregroundColor(theme.colors.secondaryContent)
                    .font(theme.fonts.footnoteSB)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibility(identifier: "headerTitleText")
            }
            if let infoText = infoText {
                HStack(spacing: 16) {
                    Image(uiImage: Asset.Images.roomAccessInfoHeaderIcon.image)
                        .renderingMode(.template)
                        .foregroundColor(theme.colors.secondaryContent)
                    Text(infoText)
                        .foregroundColor(theme.colors.secondaryContent)
                        .font(theme.fonts.footnote)
                        .accessibility(identifier: "headerInfoText")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(theme.colors.navigation)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

// MARK: - Previews

struct MatrixItemChooserSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 16) {
                MatrixItemChooserSectionHeader(title: nil, infoText: nil)
                MatrixItemChooserSectionHeader(title: "Some Title", infoText: nil)
                MatrixItemChooserSectionHeader(title: "Some Title", infoText: "A very long info text in order to see if it's well handled by the UI")
            }.theme(.light).preferredColorScheme(.light)
            VStack(spacing: 16) {
                MatrixItemChooserSectionHeader(title: nil, infoText: nil)
                MatrixItemChooserSectionHeader(title: "Some Title", infoText: nil)
                MatrixItemChooserSectionHeader(title: "Some Title", infoText: "A very long info text in order to see if it's well handled by the UI")
            }.theme(.dark).preferredColorScheme(.dark)
        }
    }
}
