//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum MatrixItemChooserRoomDirectParentsDataSourcePreselectionMode {
    case none
    case suggestedRoom
}

class MatrixItemChooserRoomDirectParentsDataSource: MatrixItemChooserDataSource {
    private let roomId: String
    private let preselectionMode: MatrixItemChooserRoomDirectParentsDataSourcePreselectionMode
    
    private(set) var preselectedItemIds: Set<String>?

    init(roomId: String, preselectionMode: MatrixItemChooserRoomDirectParentsDataSourcePreselectionMode = .none) {
        self.roomId = roomId
        self.preselectionMode = preselectionMode
    }
    
    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void) {
        let ancestorsIds = session.spaceService.directParentIds(ofRoomWithId: roomId)

        switch preselectionMode {
        case .none:
            preselectedItemIds = nil
        case .suggestedRoom:
            preselectedItemIds = session.spaceService.directParentIds(ofRoomWithId: roomId, whereRoomIsSuggested: true)
        }
        
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
