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
