//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class MatrixItemChooserRoomAncestorsDataSource: MatrixItemChooserDataSource {
    private let roomId: String
    
    var preselectedItemIds: Set<String>? { nil }

    init(roomId: String) {
        self.roomId = roomId
    }
    
    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void) {
        let ancestorsIds = session.spaceService.ancestorsPerRoomId[roomId] ?? []
        completion(Result(catching: {
            [
                MatrixListItemSectionData(title: VectorL10n.roomAccessSpaceChooserKnownSpacesSection(session.room(withRoomId: roomId)?.displayName ?? ""), items: ancestorsIds.compactMap { spaceId in
                    guard let space = session.spaceService.getSpace(withId: spaceId) else {
                        return nil
                    }
                    
                    guard let room = space.room else {
                        return nil
                    }
                    
                    return MatrixListItemData(mxRoom: room, spaceService: session.spaceService)
                }
                .sorted { $0.displayName ?? "" < $1.displayName ?? "" })
            ]
        }))
    }
}
