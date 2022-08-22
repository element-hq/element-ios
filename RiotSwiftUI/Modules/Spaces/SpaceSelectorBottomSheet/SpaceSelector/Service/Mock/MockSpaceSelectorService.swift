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

import Foundation
import Combine
import UIKit

class MockSpaceSelectorService: SpaceSelectorServiceProtocol {
    
    static let homeItem = SpaceSelectorListItemData(id: SpaceSelectorConstants.homeSpaceId, avatar: nil, icon: UIImage(systemName: "house"), displayName: "All Chats", notificationCount: 0, highlightedNotificationCount: 0, hasSubItems: false)
    static let defaultSpaceList = [
        homeItem,
        SpaceSelectorListItemData(id: "!lennfd:matrix.org", avatar: nil, icon: UIImage(systemName: "number"), displayName: "Invited space", notificationCount: 0, highlightedNotificationCount: 0, hasSubItems: false, isJoined: false),
        SpaceSelectorListItemData(id: "!aaabaa:matrix.org", avatar: nil, icon: UIImage(systemName: "number"), displayName: "Default Space", notificationCount: 0, highlightedNotificationCount: 0, hasSubItems: false, isJoined: true),
        SpaceSelectorListItemData(id: "!zzasds:matrix.org", avatar: nil, icon: UIImage(systemName: "number"), displayName: "Space with sub items", notificationCount: 0, highlightedNotificationCount: 0, hasSubItems: true, isJoined: true),
        SpaceSelectorListItemData(id: "!scthve:matrix.org", avatar: nil, icon: UIImage(systemName: "number"), displayName: "Space with notifications", notificationCount: 55, highlightedNotificationCount: 0, hasSubItems: true, isJoined: true),
        SpaceSelectorListItemData(id: "!ferggs:matrix.org", avatar: nil, icon: UIImage(systemName: "number"), displayName: "Space with highlight", notificationCount: 99, highlightedNotificationCount: 50, hasSubItems: false, isJoined: true)
    ]

    var spaceListSubject: CurrentValueSubject<[SpaceSelectorListItemData], Never>
    var parentSpaceNameSubject: CurrentValueSubject<String?, Never>
    var selectedSpaceId: String?

    init(spaceList: [SpaceSelectorListItemData] = defaultSpaceList, parentSpaceName: String? = nil, selectedSpaceId: String = SpaceSelectorConstants.homeSpaceId) {
        self.spaceListSubject = CurrentValueSubject(spaceList)
        self.parentSpaceNameSubject = CurrentValueSubject(parentSpaceName)
        self.selectedSpaceId = selectedSpaceId
    }
}
