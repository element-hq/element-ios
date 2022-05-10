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
class SpaceSelectorBottomSheetService: SpaceSelectorBottomSheetServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let spaceIds: [String]?
    
    private var spaceList: [SpaceSelectorListItemData] {
        if let spaceIds = spaceIds {
            return spaceIds.compactMap { spaceId in
                guard let summary = session.roomSummary(withRoomId: spaceId) else {
                    return nil
                }
                return SpaceSelectorListItemData(id:summary.roomId, avatar: summary.room.avatarData, displayName: summary.displayname)
            }
        } else {
            return session.spaceService.spaceSummaries.compactMap { summary in
                SpaceSelectorListItemData(id:summary.roomId, avatar: summary.room.avatarData, displayName: summary.displayname)
            }
        }
    }
    
    // MARK: Public

    private(set) var spaceListSubject: CurrentValueSubject<[SpaceSelectorListItemData], Never>
    
    // MARK: - Setup
    
    init(session: MXSession, spaceIds: [String]?) {
        self.session = session
        self.spaceIds = spaceIds
        self.spaceListSubject = CurrentValueSubject([])
        
        spaceListSubject.send(spaceList)
    }
}
