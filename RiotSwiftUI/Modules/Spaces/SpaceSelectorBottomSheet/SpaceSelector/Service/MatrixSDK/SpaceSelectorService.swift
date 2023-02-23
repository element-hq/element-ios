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

import Combine
import Foundation
import MatrixSDK

class SpaceSelectorService: SpaceSelectorServiceProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let parentSpaceId: String?
    private let showHomeSpace: Bool

    private var spaceList: [SpaceSelectorListItemData] {
        let notificationCounter = session.spaceService.notificationCounter
        
        var invitedSpaces: [SpaceSelectorListItemData] = []
        var joinedSpaces: [SpaceSelectorListItemData] = []
        if let parentSpaceId = parentSpaceId, let parentSpace = session.spaceService.getSpace(withId: parentSpaceId) {
            for space in parentSpace.childSpaces {
                guard let item = SpaceSelectorListItemData.itemData(with: space, notificationCounter: notificationCounter) else {
                    continue
                }
                
                if item.isJoined {
                    joinedSpaces.append(item)
                } else {
                    invitedSpaces.append(item)
                }
            }
        } else {
            for space in session.spaceService.rootSpaces {
                guard let item = SpaceSelectorListItemData.itemData(with: space, notificationCounter: notificationCounter) else {
                    continue
                }
                
                if item.isJoined {
                    joinedSpaces.append(item)
                } else {
                    invitedSpaces.append(item)
                }
            }
        }
        
        guard !invitedSpaces.isEmpty || !joinedSpaces.isEmpty else {
            return []
        }

        var itemList: [SpaceSelectorListItemData] = []
        itemList.append(contentsOf: invitedSpaces)
        if showHomeSpace, parentSpaceId == nil {
            itemList.append(SpaceSelectorListItemData(id: SpaceSelectorConstants.homeSpaceId, icon: Asset.Images.sideMenuActionIconFeedback.image, displayName: VectorL10n.allChatsTitle, isJoined: true))
        }
        itemList.append(contentsOf: joinedSpaces)

        return itemList
    }
    
    private var parentSpaceName: String? {
        guard let parentSpaceId = parentSpaceId, let summary = session.roomSummary(withRoomId: parentSpaceId) else {
            return nil
        }
        
        return summary.displayname
    }
    
    // MARK: Public

    private(set) var spaceListSubject: CurrentValueSubject<[SpaceSelectorListItemData], Never>
    private(set) var parentSpaceNameSubject: CurrentValueSubject<String?, Never>
    private(set) var selectedSpaceId: String?

    // MARK: - Setup
    
    init(session: MXSession, parentSpaceId: String?, showHomeSpace: Bool, selectedSpaceId: String?) {
        self.session = session
        self.parentSpaceId = parentSpaceId
        self.showHomeSpace = showHomeSpace
        spaceListSubject = CurrentValueSubject([])
        parentSpaceNameSubject = CurrentValueSubject(nil)
        self.selectedSpaceId = selectedSpaceId

        spaceListSubject.send(spaceList)
        parentSpaceNameSubject.send(parentSpaceName)
        
        NotificationCenter.default.addObserver(self, selector: #selector(spaceServiceDidUpdate), name: MXSpaceService.didBuildSpaceGraph, object: nil)
    }
    
    @objc private func spaceServiceDidUpdate() {
        spaceListSubject.send(spaceList)
    }
}

private extension SpaceSelectorListItemData {
    static func itemData(with space: MXSpace, notificationCounter: MXSpaceNotificationCounter) -> SpaceSelectorListItemData? {
        guard let summary = space.summary else {
            return nil
        }
        
        let notificationState = notificationCounter.notificationState(forSpaceWithId: space.spaceId)
        
        return SpaceSelectorListItemData(id: summary.roomId,
                                         avatar: summary.room.avatarData,
                                         displayName: summary.displayname,
                                         notificationCount: notificationState?.groupMissedDiscussionsCount ?? 0,
                                         highlightedNotificationCount: notificationState?.groupMissedDiscussionsHighlightedCount ?? 0,
                                         hasSubItems: !space.childSpaces.isEmpty,
                                         isJoined: summary.isJoined)
    }
}
