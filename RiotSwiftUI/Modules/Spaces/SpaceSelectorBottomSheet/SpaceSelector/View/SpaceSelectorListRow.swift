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
    let isJoined: Bool
    let isSelected: Bool
    let notificationCount: UInt
    let highlightedNotificationCount: UInt
    let selectionAction: (() -> Void)?
    let disclosureAction: (() -> Void)?
    
    private var name: String {
        return displayName ?? ""
    }
    
    private var acessibilityName: String {
        return notificationCount > 0 ? "\(name)\n\(VectorL10n.spaceSelectorListRowAccessibilityUnreadMessages("\(notificationCount)"))" : name
    }
    
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
                        Text(name)
                            .foregroundColor(theme.colors.primaryContent)
                            .font(theme.fonts.bodySB)
                            .accessibility(identifier: "itemName")
                        Spacer()
                        if notificationCount > 0 {
                            badge(with: "\(notificationCount)", color: highlightedNotificationCount > 0 ? theme.colors.alert : theme.colors.secondaryContent)
                        }
                        if !isJoined {
                            badge(with: "! ", color: theme.colors.alert)
                                .accessibilityHidden(true)
                            Image(systemName: "chevron.right")
                                .renderingMode(.template)
                                .foregroundColor(theme.colors.secondaryContent)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(isJoined ? acessibilityName : "invite to \(name)")
                    .accessibilityHint(isJoined ? (isSelected ? VectorL10n.spaceSelectorListRowAccessibilitySelectedSpace : VectorL10n.spaceSelectorListRowAccessibilitySwitchesTo(name)) : VectorL10n.spaceSelectorListRowAccessibilityInviteHint)
                    .accessibilityAction {
                        if !isSelected {
                            selectionAction?()
                        }
                    }
                    if hasSubItems, isJoined {
                        Button {
                            disclosureAction?()
                        } label: {
                            Image(systemName: "chevron.right")
                                .renderingMode(.template)
                                .foregroundColor(theme.colors.accent)
                        }
                        .accessibility(identifier: "disclosureButton")
                        .accessibilityLabel(VectorL10n.spaceSelectorListRowAccessibilityDisclosureLabel(name))
                        .accessibilityHint(VectorL10n.spaceSelectorListRowAccessibilityDisclosureHint(name))
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal, 8)
        .background(theme.colors.background)
        .onTapGesture {
            selectionAction?()
        }
    }

    private func badge(with text: String, color: Color) -> some View {
        Text(text)
            .multilineTextAlignment(.center)
            .foregroundColor(theme.colors.background)
            .font(theme.fonts.footnote)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(color)
            .clipShape(Capsule())
            .accessibility(identifier: "notificationBadge")
    }
}

// MARK: - Previews

struct SpaceSelectorListRow_Previews: PreviewProvider {
    static var previews: some View {
        sampleView.theme(.light).preferredColorScheme(.light)
        sampleView.theme(.dark).preferredColorScheme(.dark)
    }
    
    static var sampleView: some View {
        VStack(spacing: 8) {
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: false, isJoined: true, isSelected: false, notificationCount: 0, highlightedNotificationCount: 0, selectionAction: nil, disclosureAction: nil)
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: true, isJoined: true, isSelected: false, notificationCount: 0, highlightedNotificationCount: 0, selectionAction: nil, disclosureAction: nil)
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: true, isJoined: true, isSelected: false, notificationCount: 99, highlightedNotificationCount: 0, selectionAction: nil, disclosureAction: nil)
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: false, isJoined: true, isSelected: false, notificationCount: 99, highlightedNotificationCount: 1, selectionAction: nil, disclosureAction: nil)
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: true, isJoined: true, isSelected: true, notificationCount: 99, highlightedNotificationCount: 1, selectionAction: nil, disclosureAction: nil)
        }
    }
}
