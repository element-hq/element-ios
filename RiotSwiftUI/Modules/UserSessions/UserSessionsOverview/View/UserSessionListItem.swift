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
    
    private var sessionTitle: String {
        
        let sessionTitle: String
        
        let clientName = viewData.deviceType.name
        
        if let sessionName = viewData.sessionName {
            sessionTitle = VectorL10n.userSessionName(clientName, sessionName)
        } else {
            sessionTitle = clientName
        }
        
        return sessionTitle
    }
    
    private var sessionDetailsText: String {
        
        let sessionDetailsString: String
        
        let sessionStatusText = viewData.isVerified ? VectorL10n.userSessionVerifiedShort : VectorL10n.userSessionUnverifiedShort
        
        var lastActivityDateString: String?
        
        if let lastActivityDate = viewData.lastActivityDate {
            lastActivityDateString = self.lastActivityDateString(from: lastActivityDate)
        }

        if let lastActivityDateString = lastActivityDateString, lastActivityDateString.isEmpty == false {
            sessionDetailsString = VectorL10n.userSessionItemDetails(sessionStatusText, lastActivityDateString)
        } else {
            sessionDetailsString = sessionStatusText
        }
        
        return sessionDetailsString
    }
    
    // MARK: Public
    
    let viewData: UserSessionListItemViewData
    
    var onBackgroundTap: ((String) -> (Void))? = nil
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            HStack(spacing: 18) {
                DeviceAvatarView(viewData: viewData.deviceAvatarViewData)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sessionTitle)
                        .font(theme.fonts.bodySB)
                        .foregroundColor(theme.colors.primaryContent)
                    Text(sessionDetailsText)
                        .font(theme.fonts.caption1)
                        .foregroundColor(theme.colors.secondaryContent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15)
        .onTapGesture {
            onBackgroundTap?(self.viewData.sessionId)
        }
    }
    
    // MARK: - Private
        
    private func lastActivityDateString(from timestamp: TimeInterval) -> String? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        
        let date = Date(timeIntervalSince1970: timestamp)
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        
        return dateFormatter.string(from: date)
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
