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

struct SpaceSettingsOptionListItem: View {
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @Environment(\.isEnabled) private var isEnabled

    // MARK: - Properties
    
    let icon: UIImage?
    let title: String?
    let value: String?
    let action: (() -> Void)?
    
    // MARK: - Setup
    
    init(icon: UIImage? = nil,
         title: String? = nil,
         value: String? = nil,
         action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.action = action
    }
    
    // MARK: - Public
    
    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 16) {
                if let icon = icon {
                    Image(uiImage: icon)
                        .renderingMode(.template)
                        .frame(width: 22, height: 22)
                        .foregroundColor(theme.colors.tertiaryContent)
                }
                if let title = title {
                    Text(title)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.primaryContent)
                }
                Spacer()
                if let value = value {
                    Text(value)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.tertiaryContent)
                }
                Image(systemName: "chevron.right")
                    .renderingMode(.template)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(theme.colors.quarterlyContent)
            }
            .opacity(isEnabled ? 1 : 0.5)
        }
        .frame(height: 44)
        .padding(.horizontal)
        .background(theme.colors.background)
        .onTapGesture {
            if isEnabled {
                action?()
            }
        }
    }
}

// MARK: - Previews

struct SpaceSettingsOptionListItem_Previews: PreviewProvider {
    static var previews: some View {
        sampleView.theme(.light).preferredColorScheme(.light)
        sampleView.theme(.dark).preferredColorScheme(.dark)
    }
    
    static var sampleView: some View {
        VStack(spacing: 8) {
            SpaceSettingsOptionListItem(icon: nil, title: "Some Title", value: nil)
            SpaceSettingsOptionListItem(icon: nil, title: "Some Title", value: "Some value")
            SpaceSettingsOptionListItem(icon: Asset.Images.spaceRoomIcon.image, title: "Some Title", value: "Some value")
            SpaceSettingsOptionListItem(icon: Asset.Images.spaceRoomIcon.image, title: "Some Title", value: "Some value")
                .disabled(true)
        }
    }
}
