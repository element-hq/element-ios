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

struct SpaceSelectorListRow: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let avatar: AvatarInputProtocol?
    let icon: UIImage?
    let displayName: String?
    let hasSubItems: Bool
    let isSelected: Bool
    let notificationCount: UInt
    let highlightedNotificationCount: UInt
    let disclosureAction: (() -> Void)?
    
    @ViewBuilder
    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.colors.system)
                    .padding(.horizontal, 8)
            }
            VStack {
                HStack {
                    if let avatar = avatar {
                        SpaceAvatarImage(avatarData: avatar, size: .xSmall)
                    }
                    if let icon = icon {
                        Image(uiImage: icon)
                            .renderingMode(.template)
                            .foregroundColor(theme.colors.primaryContent)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.quinaryContent)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Text(displayName ?? "")
                        .foregroundColor(theme.colors.primaryContent)
                        .font(theme.fonts.bodySB)
                        .accessibility(identifier: "itemNameText")
                    Spacer()
                    if notificationCount > 0 {
                        Text("\(notificationCount)")
                            .multilineTextAlignment(.center)
                            .foregroundColor(theme.colors.background)
                            .font(theme.fonts.footnote)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(highlightedNotificationCount > 0 ? theme.colors.alert : theme.colors.secondaryContent)
                            .clipShape(Capsule())
                            .accessibility(identifier: "notificationBadge")
                    }
                    if hasSubItems {
                        Button {
                            disclosureAction?()
                        } label: {
                            Image(systemName: "chevron.right")
                                .renderingMode(.template)
                                .foregroundColor(theme.colors.accent)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(theme.colors.background)
    }

}
