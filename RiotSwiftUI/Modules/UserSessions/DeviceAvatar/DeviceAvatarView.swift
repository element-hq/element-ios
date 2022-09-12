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
import DesignKit

/// Avatar view for device
struct DeviceAvatarView: View {
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    var viewData: DeviceAvatarViewData
        
    var avatarSize: CGFloat = 40
    var badgeSize: CGFloat = 24
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            // Device image
            VStack(alignment: .center) {
                viewData.deviceType.image
            }
            .padding()
            .frame(maxWidth: CGFloat(avatarSize), maxHeight: CGFloat(avatarSize))
            .background(theme.colors.system)
            .clipShape(Circle())
            
            // Verification badge
            if let isVerified = viewData.isVerified {
                
                Image(isVerified ? Asset.Images.userSessionVerified.name : Asset.Images.userSessionUnverified.name)
                    .frame(maxWidth: CGFloat(badgeSize), maxHeight: CGFloat(badgeSize))
                    .shapedBorder(color: theme.colors.system, borderWidth: 1, shape: Circle())
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
        return [
            DeviceAvatarViewData(deviceType: .desktop, isVerified: true),
            DeviceAvatarViewData(deviceType: .web, isVerified: true),
            DeviceAvatarViewData(deviceType: .mobile, isVerified: true),
            DeviceAvatarViewData(deviceType: .unknown, isVerified: true)
        ]
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 20) {
                DeviceAvatarView(viewData: DeviceAvatarViewData.init(deviceType: .web, isVerified: true))
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .desktop, isVerified: false))
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .mobile, isVerified: true))
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .unknown, isVerified: false))
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
