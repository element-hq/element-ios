//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import DesignKit
import SwiftUI

/// Avatar view for device
struct DeviceAvatarView: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    var viewData: DeviceAvatarViewData
    var isSelected: Bool
    var showVerificationBadge: Bool = true

    var avatarSize: CGFloat = 40
    var badgeSize: CGFloat = 24
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Device image
            VStack(alignment: .center) {
                viewData.deviceType.image
                    .renderingMode(isSelected ? .template : .original)
                    .foregroundColor(isSelected ? theme.colors.background : nil)
            }
            .padding()
            .frame(maxWidth: CGFloat(avatarSize), maxHeight: CGFloat(avatarSize))
            .background(isSelected ? theme.colors.primaryContent : theme.colors.system)
            .clipShape(Circle())
            
            if showVerificationBadge {
                Image(viewData.verificationImageName)
                    .frame(maxWidth: CGFloat(badgeSize), maxHeight: CGFloat(badgeSize))
                    .shapedBorder(color: theme.colors.quinaryContent, borderWidth: 1, shape: Circle())
                    .background(theme.colors.background)
                    .clipShape(Circle())
                    .offset(x: 10, y: 8)
            }
        }
        .frame(maxWidth: CGFloat(avatarSize), maxHeight: CGFloat(avatarSize))
    }
}

struct DeviceAvatarViewListPreview: View {
    var viewDataList: [DeviceAvatarViewData] {
        [
            DeviceAvatarViewData(deviceType: .desktop, verificationState: .verified),
            DeviceAvatarViewData(deviceType: .web, verificationState: .verified),
            DeviceAvatarViewData(deviceType: .mobile, verificationState: .verified),
            DeviceAvatarViewData(deviceType: .unknown, verificationState: .verified)
        ]
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 20) {
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .web, verificationState: .verified), isSelected: false)
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .desktop, verificationState: .unverified), isSelected: false)
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .mobile, verificationState: .verified), isSelected: false)
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .unknown, verificationState: .unverified), isSelected: false)
            }
        }
    }
}

struct DeviceAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceAvatarViewListPreview().theme(.light).preferredColorScheme(.light)
            DeviceAvatarViewListPreview().theme(.dark).preferredColorScheme(.dark)
        }
    }
}
