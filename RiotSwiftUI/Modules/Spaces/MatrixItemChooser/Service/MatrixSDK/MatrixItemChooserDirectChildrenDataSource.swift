//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class MatrixItemChooserDirectChildrenDataSource: MatrixItemChooserDataSource {
    // MARK: - Private
    
    private let parentId: String

    // MARK: - Setup
    
    init(parentId: String) {
        self.parentId = parentId
    }

    // MARK: - MatrixItemChooserDataSource
    
    var preselectedItemIds: Set<String>? { nil }

    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void) {
        let space = session.spaceService.getSpace(withId: parentId)
        let children: [MatrixListItemData] = space?.childRoomIds.compactMap { roomId in
            guard let room = session.room(withRoomId: roomId), !room.isDirect else {
                return nil
            }
            
            return MatrixListItemData(mxRoom: room, spaceService: session.spaceService)
        } ?? []
        completion(Result(catching: {
            [
                MatrixListItemSectionData(items: children)
            ]
        }))
    }
}
