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

import DesignKit
import SwiftUI

/// Avatar view for device
struct DeviceAvatarView: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    var viewData: DeviceAvatarViewData
    var isSelected: Bool

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
            
            // Verification badge
            Image(viewData.verificationImageName)
                .frame(maxWidth: CGFloat(badgeSize), maxHeight: CGFloat(badgeSize))
                .shapedBorder(color: theme.colors.system, borderWidth: 1, shape: Circle())
                .background(theme.colors.background)
                .clipShape(Circle())
                .offset(x: 10, y: 8)
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
