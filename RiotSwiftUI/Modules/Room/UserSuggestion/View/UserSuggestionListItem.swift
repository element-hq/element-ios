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

struct UserSuggestionListItem: View {
    // MARK: - Properties
    
    // MARK: Private

    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public

    let avatar: AvatarInputProtocol?
    let displayName: String?
    let userId: String
    
    var body: some View {
        HStack {
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

// MARK: - Previews

struct UserSuggestionHeader_Previews: PreviewProvider {
    static var previews: some View {
        UserSuggestionListItem(avatar: MockAvatarInput.example, displayName: "Alice", userId: "@alice:matrix.org")
            .addDependency(MockAvatarService.example)
    }
}
