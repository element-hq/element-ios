// 
// Copyright 2023 New Vector Ltd
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
