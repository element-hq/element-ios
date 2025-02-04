//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomNotificationSettingsHeader: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    var avatarData: AvatarInputProtocol
    var displayName: String?
    
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
                AvatarImage(avatarData: avatarData, size: .xxLarge)
                if let displayName = displayName {
                    Text(displayName)
                        .font(theme.fonts.title3SB)
                        .foregroundColor(theme.colors.primaryContent)
                        .textCase(nil)
                }
            }
            Spacer()
        }
        .padding(.top, 36)
    }
}

struct RoomNotificationSettingsHeader_Previews: PreviewProvider {
    static let name = "Element"
    static var previews: some View {
        RoomNotificationSettingsHeader(avatarData: MockAvatarInput.example, displayName: name)
            .environmentObject(AvatarViewModel.withMockedServices())
    }
}
