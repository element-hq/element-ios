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

@available(iOS 14.0, *)
class SpaceSelectorService: SpaceSelectorServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let parentSpaceId: String?
    private let showHomeSpace: Bool

    private var spaceList: [SpaceSelectorListItemData] {
        var itemList = showHomeSpace && parentSpaceId == nil ? [SpaceSelectorListItemData(id: SpaceSelectorListItemDataHomeSpaceId, avatar: nil, icon: Asset.Images.sideMenuActionIconFeedback.image, displayName: VectorL10n.allChatsTitle, hasSubItems: false)] : []
        
        if let parentSpaceId = parentSpaceId, let parentSpace = session.spaceService.getSpace(withId: parentSpaceId) {
            itemList.append(contentsOf: parentSpace.childSpaces.compactMap { space in
                guard let summary = space.summary else {
                    return nil
                }
                
                return SpaceSelectorListItemData(id:summary.roomId, avatar: summary.room.avatarData, icon: nil, displayName: summary.displayname, hasSubItems: !space.childSpaces.isEmpty)
            })
        } else {
            itemList.append(contentsOf: session.spaceService.rootSpaces.compactMap { space in
                guard let summary = space.summary else {
                    return nil
                }
                
                return SpaceSelectorListItemData(id:summary.roomId, avatar: summary.room.avatarData, icon: nil, displayName: summary.displayname, hasSubItems: !space.childSpaces.isEmpty)
            })
        }
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
        self.spaceListSubject = CurrentValueSubject([])
        self.parentSpaceNameSubject = CurrentValueSubject(nil)
        self.selectedSpaceId = selectedSpaceId

        spaceListSubject.send(spaceList)
        parentSpaceNameSubject.send(parentSpaceName)
    }
}
