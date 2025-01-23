//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

class LeaveSpaceItemsProcessor: MatrixItemChooserProcessorProtocol {
    // MARK: Private
    
    private let spaceId: String
    private let session: MXSession

    // MARK: Setup
    
    init(spaceId: String, session: MXSession) {
        self.spaceId = spaceId
        self.session = session
        dataSource = MatrixItemChooserDirectChildrenDataSource(parentId: spaceId)
    }
    
    // MARK: MatrixItemChooserSelectionProcessorProtocol
    
    private(set) var dataSource: MatrixItemChooserDataSource
    
    var loadingText: String? {
        VectorL10n.roomAccessSettingsScreenSettingRoomAccess
    }
    
    func computeSelection(withIds itemsIds: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let space = session.spaceService.getSpace(withId: spaceId) else {
            return
        }

        leaveAllRooms(from: itemsIds, at: 0) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.leaveSpace(space, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func isItemIncluded(_ item: MatrixListItemData) -> Bool {
        true
    }
    
    // MARK: Private

    /// Leave room with room ID from `roomIds` at `index`.
    /// Recurse to the next index once done.
    private func leaveAllRooms(from roomIds: [String], at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard index < roomIds.count else {
            completion(.success(()))
            return
        }
        
        guard let room = session.room(withRoomId: roomIds[index]), !room.isDirect else {
            leaveAllRooms(from: roomIds, at: index + 1, completion: completion)
            return
        }

        MXLog.debug("[LeaveSpaceItemsProcessor] leaving room \(room.displayName ?? room.roomId)")
        room.leave { [weak self] response in
            guard let self = self else { return }

            switch response {
            case .success:
                self.leaveAllRooms(from: roomIds, at: index + 1, completion: completion)
            case .failure(let error):
                MXLog.error("[LeaveSpaceItemsProcessor] failed to leave room", context: error)
                completion(.failure(error))
            }
        }
    }
    
    private func leaveSpace(_ space: MXSpace, completion: @escaping (Result<Void, Error>) -> Void) {
        MXLog.debug("[LeaveSpaceItemsProcessor] leaving space")
        space.room?.leave(completion: { response in
            switch response {
            case .success:
                completion(.success(()))
            case .failure(let error):
                MXLog.error("[LeaveSpaceItemsProcessor] failed to leave space", context: error)
                completion(.failure(error))
            }
        })
    }
}
