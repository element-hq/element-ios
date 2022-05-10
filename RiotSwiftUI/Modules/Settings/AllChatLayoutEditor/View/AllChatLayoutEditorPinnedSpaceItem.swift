// 
// Copyright 2022 New Vector Ltd
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

struct AllChatLayoutEditorPinnedSpaceItem: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let avatar: AvatarInputProtocol?
    let image: UIImage?
    let displayName: String?
    let isDeletable: Bool
    
    @ViewBuilder
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center) {
                if let avatar = avatar {
                    SpaceAvatarImage(avatarData: avatar, size: .xLarge)
                }
                if let image = image {
                    Image(uiImage: image)
                        .renderingMode(.template)
                        .foregroundColor(theme.colors.secondaryContent)
                        .frame(width: 52, height: 52)
                        .background(RoundedCornerShape(radius: 8, corners: .allCorners).fill(theme.colors.background))
                }
                Text(displayName ?? "")
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.colors.primaryContent)
                    .font(theme.fonts.footnote)
                    .frame(maxWidth: 72, maxHeight: .infinity)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            if isDeletable {
                Image(systemName: "minus")
                    .renderingMode(.template)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .frame(width: 24, height: 24)
                    .background(Circle()
                        .strokeBorder(theme.colors.navigation, lineWidth: 2, antialiased: true)
                        .background(Circle().fill(theme.colors.quinaryContent)))
            }
        }
        .frame(maxWidth: 90, maxHeight: .infinity)
    }

}
