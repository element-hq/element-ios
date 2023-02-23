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
