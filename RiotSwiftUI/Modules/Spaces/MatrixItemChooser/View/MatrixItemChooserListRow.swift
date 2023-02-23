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
            .addDependency(MockAvatarService.example)
    }
}
