//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateRoomListRow: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let avatar: AvatarInputProtocol
    let displayName: String?
    
    var body: some View {
        HStack {
            AvatarImage(avatarData: avatar, size: .medium)
            Text(displayName ?? "")
                .foregroundColor(theme.colors.primaryContent)
                .accessibility(identifier: "roomNameText")
            Spacer()
        }
        // add to a style
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

struct TemplateRoomListRow_Previews: PreviewProvider {
    static var previews: some View {
        TemplateRoomListRow(avatar: MockAvatarInput.example, displayName: "Alice")
            .environmentObject(AvatarViewModel.withMockedServices())
    }
}
