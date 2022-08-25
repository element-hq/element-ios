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

struct LiveLocationListItem: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let viewData: LiveLocationListItemViewData
    
    var timeoutText: String {
        let timeLeftString: String
        
        if let elapsedTimeString = elapsedTimeString(from: viewData.expirationDate, isPastDate: false) {
            timeLeftString = VectorL10n.locationSharingLiveListItemTimeLeft(elapsedTimeString)
        } else {
            timeLeftString = VectorL10n.locationSharingLiveListItemSharingExpired
        }
        
        return timeLeftString
    }
    
    var lastUpdateText: String {
        let timeLeftString: String
        
        if let elapsedTimeString = elapsedTimeString(from: viewData.lastUpdate, isPastDate: true) {
            timeLeftString = VectorL10n.locationSharingLiveListItemLastUpdate(elapsedTimeString)
        } else {
            timeLeftString = VectorL10n.locationSharingLiveListItemLastUpdateInvalid
        }
                
        return timeLeftString
    }
    
    var displayName: String {
        viewData.isCurrentUser ? VectorL10n.locationSharingLiveListItemCurrentUserDisplayName : viewData.displayName
    }
    
    var onStopSharingAction: (() -> Void)?
    
    var onBackgroundTap: ((String) -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            HStack(spacing: 18) {
                AvatarImage(avatarData: viewData.avatarData, size: .medium)
                    .border()
                VStack(alignment: .leading, spacing: 2) { Text(displayName)
                    .font(theme.fonts.bodySB)
                    .foregroundColor(theme.colors.primaryContent)
                    Text(timeoutText)
                        .font(theme.fonts.caption1)
                        .foregroundColor(theme.colors.primaryContent)
                    Text(lastUpdateText)
                        .font(theme.fonts.caption1)
                        .foregroundColor(theme.colors.secondaryContent)
                }
            }
            if viewData.isCurrentUser {
                Spacer()
                Button(VectorL10n.locationSharingLiveListItemStopSharingAction) {
                    onStopSharingAction?()
                }
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.alert)
            }
        }
        .onTapGesture {
            onBackgroundTap?(self.viewData.userId)
        }
    }
    
    // MARK: - Private
        
    private func elapsedTimeString(from timestamp: TimeInterval, isPastDate: Bool) -> String? {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        
        let date = Date(timeIntervalSince1970: timestamp)
        
        let elaspedTimeinterval = date.timeIntervalSinceNow
                
        var timeLeftString: String?
        
        // Negative value indicate that the timestamp is in the past
        // Positive value indicate that the timestamp is in the future
        // Return nil if the sign is not the one as expected
        if (isPastDate && elaspedTimeinterval <= 0) || (!isPastDate && elaspedTimeinterval >= 0) {
            timeLeftString = formatter.string(from: abs(elaspedTimeinterval))
        }
        
        return timeLeftString
    }
}

struct LiveLocationListPreview: View {
    let liveLocationSharingViewerService: LiveLocationSharingViewerServiceProtocol = MockLiveLocationSharingViewerService()
        
    var viewDataList: [LiveLocationListItemViewData] {
        listItemsViewData(from: liveLocationSharingViewerService.usersLiveLocation)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(viewDataList) { viewData in
                LiveLocationListItem(viewData: viewData, onStopSharingAction: { }, onBackgroundTap: { _ in
                    
                })
            }
            Spacer()
        }
        .padding()
    }
    
    private func listItemsViewData(from usersLiveLocation: [UserLiveLocation]) -> [LiveLocationListItemViewData] {
        var listItemsViewData: [LiveLocationListItemViewData] = []
        
        let sortedUsersLiveLocation = usersLiveLocation.sorted { userLiveLocation1, userLiveLocation2 in
            userLiveLocation1.displayName > userLiveLocation2.displayName
        }
        
        listItemsViewData = sortedUsersLiveLocation.map { userLiveLocation in
            self.listItemViewData(from: userLiveLocation)
        }
        
        let currentUserIndex = listItemsViewData.firstIndex { viewData in
            viewData.isCurrentUser
        }
        
        // Move current user as first item
        if let currentUserIndex = currentUserIndex {
            let currentUserViewData = listItemsViewData[currentUserIndex]
            listItemsViewData.remove(at: currentUserIndex)
            listItemsViewData.insert(currentUserViewData, at: 0)
        }
        
        return listItemsViewData
    }
    
    private func listItemViewData(from userLiveLocation: UserLiveLocation) -> LiveLocationListItemViewData {
        let isCurrentUser = liveLocationSharingViewerService.isCurrentUserId(userLiveLocation.userId)
        
        let expirationDate = userLiveLocation.timestamp + userLiveLocation.timeout
                
        return LiveLocationListItemViewData(userId: userLiveLocation.userId, isCurrentUser: isCurrentUser, avatarData: userLiveLocation.avatarData, displayName: userLiveLocation.displayName, expirationDate: expirationDate, lastUpdate: userLiveLocation.lastUpdate)
    }
}

struct LiveLocationListItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LiveLocationListPreview().theme(.light).preferredColorScheme(.light)
            LiveLocationListPreview().theme(.dark).preferredColorScheme(.dark)
        }
    }
}
