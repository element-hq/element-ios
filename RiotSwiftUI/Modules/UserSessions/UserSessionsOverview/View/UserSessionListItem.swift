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
            HStack(spacing: 18) {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15)
    }
}

struct UserSessionListPreview: View {
    
    let userSessionsOverviewService: UserSessionsOverviewServiceProtocol = MockUserSessionsOverviewService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(userSessionsOverviewService.lastOverviewData.otherSessionsInfo) { userSessionInfo in
                let viewData = UserSessionListItemViewData(userSessionInfo: userSessionInfo)

                UserSessionListItem(viewData: viewData, onBackgroundTap: { sessionId in

                })
            }
            Spacer()
        }
        .padding()
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
