//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class AddRoomItemsProcessor: MatrixItemChooserProcessorProtocol {
    // MARK: Private
    
    private let parentSpace: MXSpace
    
    // MARK: Setup
    
    init(parentSpace: MXSpace) {
        self.parentSpace = parentSpace
    }
    
    // MARK: MatrixItemChooserSelectionProcessorProtocol
    
    private(set) var dataSource: MatrixItemChooserDataSource = MatrixItemChooserRoomsDataSource()
    
    var loadingText: String? {
        nil
    }
    
    func computeSelection(withIds itemsIds: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        addChild(from: itemsIds, at: 0, completion: completion)
    }
    
    func isItemIncluded(_ item: MatrixListItemData) -> Bool {
        !parentSpace.isRoomAChild(roomId: item.id)
    }
    
    // MARK: Private
    
    /// Add room with roomId from list of room IDs at index to the parentSpace.
    /// Recurse to the next index once done.
    func addChild(from roomIds: [String], at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard index < roomIds.count else {
            // last item has been processed or list is empty --> the recursion has finished
            completion(Result.success(()))
            return
        }
        
        let roomId = roomIds[index]
        
        guard !parentSpace.isRoomAChild(roomId: roomId) else {
            addChild(from: roomIds, at: index + 1, completion: completion)
            return
        }
        
        parentSpace.addChild(roomId: roomIds[index]) { [weak self] response in
            switch response {
            case .success:
                self?.addChild(from: roomIds, at: index + 1, completion: completion)
            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }
}
