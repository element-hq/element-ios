//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomAccessTypeChooserRow: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let isSelected: Bool
    let title: String
    let message: String
    let badgeText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .foregroundColor(theme.colors.primaryContent)
                        .font(theme.fonts.body)
                    Text(message)
                        .foregroundColor(theme.colors.secondaryContent)
                        .font(theme.fonts.subheadline)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .renderingMode(.template)
                    .foregroundColor(isSelected ? theme.colors.accent : theme.colors.quarterlyContent)
            }
            if let badgeText = badgeText {
                Text(badgeText)
                    .foregroundColor(theme.colors.accent)
                    .font(theme.fonts.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder()
                            .foregroundColor(theme.colors.accent)
                    )
            }
            Divider().background(theme.colors.quinaryContent)
        }
        .background(theme.colors.background)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

struct RoomAccessTypeChooserRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RoomAccessTypeChooserRow(isSelected: false, title: "Title of the row", message: "Some very long message just to figure out if the row behaves as expected", badgeText: nil)
            RoomAccessTypeChooserRow(isSelected: false, title: "Title of the row", message: "Some very long message just to figure out if the row behaves as expected", badgeText: "Badge Text")
            RoomAccessTypeChooserRow(isSelected: true, title: "Title of the row", message: "Some very long message just to figure out if the row behaves as expected", badgeText: nil)
            RoomAccessTypeChooserRow(isSelected: true, title: "Title of the row", message: "Some very long message just to figure out if the row behaves as expected", badgeText: "Badge Text")
        }.theme(.light).preferredColorScheme(.light)
        VStack {
            RoomAccessTypeChooserRow(isSelected: false, title: "Title of the row", message: "Some very long message just to figure out if the row behaves as expected", badgeText: nil)
            RoomAccessTypeChooserRow(isSelected: false, title: "Title of the row", message: "Some very long message just to figure out if the row behaves as expected", badgeText: "Badge Text")
            RoomAccessTypeChooserRow(isSelected: true, title: "Title of the row", message: "Some very long message just to figure out if the row behaves as expected", badgeText: nil)
            RoomAccessTypeChooserRow(isSelected: true, title: "Title of the row", message: "Some very long message just to figure out if the row behaves as expected", badgeText: "Badge Text")
        }.theme(.dark).preferredColorScheme(.dark)
    }
}
