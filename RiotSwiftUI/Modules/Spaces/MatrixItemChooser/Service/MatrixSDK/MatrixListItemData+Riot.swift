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

extension MatrixListItemData {
    init(mxUser: MXUser) {
        self.init(id: mxUser.userId, type: .user, avatar: mxUser.avatarData, displayName: mxUser.displayname, detailText: mxUser.userId)
    }
    
    init(mxRoom: MXRoom, spaceService: MXSpaceService) {
        let parentSpaceIds = mxRoom.summary.parentSpaceIds ?? Set()
        let detailText: String?
        if parentSpaceIds.isEmpty {
            detailText = nil
        } else {
            if let spaceName = spaceService.getSpace(withId: parentSpaceIds.first ?? "")?.summary?.displayname {
                let count = parentSpaceIds.count - 1
                switch count {
                case 0:
                    detailText = VectorL10n.spacesCreationInSpacename(spaceName)
                case 1:
                    detailText = VectorL10n.spacesCreationInSpacenamePlusOne(spaceName)
                default:
                    detailText = VectorL10n.spacesCreationInSpacenamePlusMany(spaceName, "\(count)")
                }
            } else {
                if parentSpaceIds.count > 1 {
                    detailText = VectorL10n.spacesCreationInManySpaces("\(parentSpaceIds.count)")
                } else {
                    detailText = VectorL10n.spacesCreationInOneSpace
                }
            }
        }
        let type: MatrixListItemDataType
        if let summary = mxRoom.summary, summary.roomType == .space {
            type = .space
        } else {
            type = .room
        }
        self.init(id: mxRoom.roomId, type: type, avatar: mxRoom.avatarData, displayName: mxRoom.summary.displayname, detailText: detailText)
    }
}
