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
            .addDependency(MockAvatarService.example)
    }
}
