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

struct UserSessionListItem: View {
    
    // MARK: - Constants
    
    private enum LayoutConstants {
        static let horizontalPadding: CGFloat = 15
        static let verticalPadding: CGFloat = 16
        static let avatarWidth: CGFloat = 40
        static let avatarRightMargin: CGFloat = 18
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    // MARK: Public
    
    let viewData: UserSessionListItemViewData
    
    var onBackgroundTap: ((String) -> (Void))? = nil
    
    // MARK: - Body
    
    var body: some View {
        Button(action: { onBackgroundTap?(self.viewData.sessionId)
        }) {
            VStack(alignment: .leading, spacing: LayoutConstants.verticalPadding) {
                HStack(spacing: LayoutConstants.avatarRightMargin) {
                    DeviceAvatarView(viewData: viewData.deviceAvatarViewData)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewData.sessionName)
                            .font(theme.fonts.bodySB)
                            .foregroundColor(theme.colors.primaryContent)
                            .multilineTextAlignment(.leading)
                        
                        Text(viewData.sessionDetails)
                            .font(theme.fonts.caption1)
                            .foregroundColor(theme.colors.secondaryContent)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LayoutConstants.horizontalPadding)
                
                // Separator
                // Note: Separator leading is matching the text leading, we could use alignment guide in the future
                Rectangle()
                    .fill(theme.colors.quinaryContent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(height: 1.0)
                    .padding(.leading, LayoutConstants.horizontalPadding + LayoutConstants.avatarRightMargin + LayoutConstants.avatarWidth)
            }
            .padding(.top, LayoutConstants.verticalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UserSessionListPreview: View {
    
    let userSessionsOverviewService: UserSessionsOverviewServiceProtocol = MockUserSessionsOverviewService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(userSessionsOverviewService.lastOverviewData.otherSessionsInfo) { userSessionInfo in
                let viewData = UserSessionListItemViewData(userSessionInfo: userSessionInfo)

                UserSessionListItem(viewData: viewData, onBackgroundTap: { sessionId in

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
        }
    }
}
