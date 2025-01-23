//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct MatrixItemChooserListRow: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let avatar: AvatarInputProtocol
    let type: MatrixListItemDataType
    let displayName: String?
    let detailText: String?
    let isSelected: Bool
    
    @ViewBuilder
    var body: some View {
        HStack {
            if type == .space {
                SpaceAvatarImage(avatarData: avatar, size: .small)
            } else {
                AvatarImage(avatarData: avatar, size: .small)
            }
            VStack(alignment: .leading) {
                Text(displayName ?? "")
                    .foregroundColor(theme.colors.primaryContent)
                    .font(theme.fonts.callout)
                    .accessibility(identifier: "itemNameText")
                if let detailText = self.detailText {
                    Text(detailText)
                        .foregroundColor(theme.colors.secondaryContent)
                        .font(theme.fonts.footnote)
                        .accessibility(identifier: "itemDetailText")
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill").renderingMode(.template).foregroundColor(theme.colors.accent)
            } else {
                Image(systemName: "circle").renderingMode(.template).foregroundColor(theme.colors.tertiaryContent)
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

struct MatrixItemChooserListRow_Previews: PreviewProvider {
    static var previews: some View {
        TemplateRoomListRow(avatar: MockAvatarInput.example, displayName: "Alice")
            .environmentObject(AvatarViewModel.withMockedServices())
    }
}
