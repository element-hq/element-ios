//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct CompletionSuggestionListItem: View {
    // MARK: - Properties
    
    // MARK: Private

    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public

    let content: CompletionSuggestionViewStateItem
    
    var body: some View {
        HStack {
            switch content {
            case .command(let name, let parametersFormat, let description):
                VStack(alignment: .leading) {
                    HStack {
                        Text(name)
                            .font(theme.fonts.body.bold())
                            .foregroundColor(theme.colors.primaryContent)
                            .accessibility(identifier: "nameText")
                            .lineLimit(1)
                        Text(parametersFormat)
                            .font(theme.fonts.body.italic())
                            .foregroundColor(theme.colors.tertiaryContent)
                            .accessibility(identifier: "parametersFormatText")
                            .lineLimit(1)
                    }
                    Text(description)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.tertiaryContent)
                        .accessibility(identifier: "descriptionText")
                }
            case .user(let userId, let avatar, let displayName):
                if let avatar = avatar {
                    AvatarImage(avatarData: avatar, size: .medium)
                }
                VStack(alignment: .leading) {
                    Text(displayName ?? "")
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.primaryContent)
                        .accessibility(identifier: "displayNameText")
                        .lineLimit(1)
                    Text(userId)
                        .font(theme.fonts.footnote)
                        .foregroundColor(theme.colors.tertiaryContent)
                        .accessibility(identifier: "userIdText")
                        .lineLimit(1)
                }
            }
        }
    }
}

// MARK: - Previews

struct CompletionSuggestionHeader_Previews: PreviewProvider {
    static var previews: some View {
        CompletionSuggestionListItem(content: CompletionSuggestionViewStateItem.user(
            id: "@alice:matrix.org",
            avatar: MockAvatarInput.example,
            displayName: "Alice"
        ))
        .environmentObject(AvatarViewModel.withMockedServices())
    }
}
