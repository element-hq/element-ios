// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomWaitingForMembers: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    var body: some View {
        ZStack {
            HStack(alignment: .top) {
                Image(uiImage: Asset.Images.membersListIcon.image)
                VStack(alignment: .leading, spacing: 6) {
                    Text(VectorL10n.roomWaitingOtherParticipantsTitle(AppInfo.current.displayName))
                        .font(theme.fonts.bodySB)
                        .foregroundColor(theme.colors.primaryContent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(VectorL10n.roomWaitingOtherParticipantsMessage(AppInfo.current.displayName))
                        .font(theme.fonts.caption1)
                        .foregroundColor(theme.colors.secondaryContent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(9)
            .background(theme.colors.system)
            .cornerRadius(4)
        }
    }
}

struct RoomWaitingForMembers_Previews: PreviewProvider {
    static var previews: some View {
        RoomWaitingForMembers()
            .padding(16)
    }
}
