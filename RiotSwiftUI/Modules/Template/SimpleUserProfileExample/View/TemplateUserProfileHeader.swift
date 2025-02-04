//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateUserProfileHeader: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI

    let avatar: AvatarInputProtocol?
    let displayName: String?
    let presence: TemplateUserProfilePresence
    
    var body: some View {
        VStack {
            if let avatar = avatar {
                AvatarImage(avatarData: avatar, size: .xxLarge)
                    .padding(.vertical)
            }
            VStack(spacing: 8) {
                Text(displayName ?? "")
                    .font(theme.fonts.title3)
                    .accessibility(identifier: "displayNameText")
                    .padding(.horizontal)
                    .lineLimit(1)
                TemplateUserProfilePresenceView(presence: presence)
            }
        }
    }
}

// MARK: - Previews

struct TemplateUserProfileHeader_Previews: PreviewProvider {
    static var previews: some View {
        TemplateUserProfileHeader(avatar: MockAvatarInput.example, displayName: "Alice", presence: .online)
            .environmentObject(AvatarViewModel.withMockedServices())
    }
}
