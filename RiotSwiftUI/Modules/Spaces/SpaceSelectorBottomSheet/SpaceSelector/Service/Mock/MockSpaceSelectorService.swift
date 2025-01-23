//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
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
        spaceListSubject = CurrentValueSubject(spaceList)
        parentSpaceNameSubject = CurrentValueSubject(parentSpaceName)
        self.selectedSpaceId = selectedSpaceId
    }
}
