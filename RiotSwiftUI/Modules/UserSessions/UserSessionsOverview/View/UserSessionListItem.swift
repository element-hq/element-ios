//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserSessionListItem: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let viewData: UserSessionListItemViewData
    let showsLocationInfo: Bool
    
    var isSeparatorHidden = false
    var isEditModeEnabled = false
    var onBackgroundTap: ((String) -> Void)?
    var onBackgroundLongPress: ((String) -> Void)?
    
    var body: some View {
        Button { } label: {
            ZStack {
                if viewData.isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.colors.system)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                }
                HStack {
                    if isEditModeEnabled {
                        Image(viewData.isSelected ? Asset.Images.userSessionListItemSelected.name : Asset.Images.userSessionListItemNotSelected.name)
                    }
                    DeviceAvatarView(viewData: viewData.deviceAvatarViewData, isSelected: viewData.isSelected)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewData.sessionName)
                            .lineLimit(1)
                            .font(theme.fonts.headline)
                            .foregroundColor(theme.colors.primaryContent)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 16)
                            .padding(.bottom, 2)
                            .padding(.trailing, 16)
                        HStack(alignment: .top) {
                            if let sessionDetailsIcon = viewData.sessionDetailsIcon {
                                Image(sessionDetailsIcon)
                                    .padding(.leading, 2)
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                Text(viewData.sessionDetails)
                                
                                if showsLocationInfo, let ipText = ipText {
                                    Text(ipText)
                                }
                            }
                            .font(theme.fonts.caption1)
                            .foregroundColor(theme.colors.secondaryContent)
                            .multilineTextAlignment(.leading)
                        }
                        .padding(.bottom, 16)
                        .padding(.trailing, 16)
                        SeparatorLine(height: 0.5)
                            .isHidden(isSeparatorHidden)
                    }
                    .padding(.leading, 7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onBackgroundTap?(viewData.sessionId)
            }
            .onLongPressGesture {
                onBackgroundLongPress?(viewData.sessionId)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("UserSessionListItem_\(viewData.sessionId)")
    }
    
    private var ipText: String? {
        guard let lastSeenIp = viewData.lastSeenIP, !lastSeenIp.isEmpty else {
            return nil
        }
        return viewData.lastSeenIPLocation.map { "\(lastSeenIp) (\($0))" } ?? lastSeenIp
    }
}

struct UserSessionListPreview: View {
    let userSessionsOverviewService: UserSessionsOverviewServiceProtocol = MockUserSessionsOverviewService()
    var isEditModeEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(userSessionsOverviewService.otherSessions) { userSessionInfo in
                let viewData = UserSessionListItemViewDataFactory().create(from: userSessionInfo)
                UserSessionListItem(viewData: viewData, showsLocationInfo: true, isEditModeEnabled: isEditModeEnabled, onBackgroundTap: { _ in
                })
            }
        }
    }
}

struct UserSessionListItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserSessionListPreview().theme(.light).preferredColorScheme(.light)
            UserSessionListPreview().theme(.dark).preferredColorScheme(.dark)
            UserSessionListPreview(isEditModeEnabled: true).theme(.light).preferredColorScheme(.light)
            UserSessionListPreview(isEditModeEnabled: true).theme(.dark).preferredColorScheme(.dark)
        }
    }
}
