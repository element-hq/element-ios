//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
            if let spaceName = spaceService.getSpace(withId: parentSpaceIds.first ?? "")?.summary?.displayName {
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
        self.init(id: mxRoom.roomId, type: type, avatar: mxRoom.avatarData, displayName: mxRoom.summary.displayName, detailText: detailText)
    }
}
