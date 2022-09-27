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
