//
// Copyright 2021 New Vector Ltd
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
