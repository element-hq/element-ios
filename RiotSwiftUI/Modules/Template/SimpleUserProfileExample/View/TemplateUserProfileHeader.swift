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

struct TemplateUserProfileHeader: View {
    
    // MARK: - Properties
    
    // MARK: Private
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    let avatar: AvatarInputProtocol?
    let displayName: String?
    let presence: TemplateUserProfilePresence
    
    var body: some View {
        VStack {
            if let avatar = avatar {
                AvatarImage(avatarData: avatar, size: .xxLarge)
                .padding(.vertical)
            }
            VStack(spacing: 8){
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
            .addDependency(MockAvatarService.example)
    }
}
