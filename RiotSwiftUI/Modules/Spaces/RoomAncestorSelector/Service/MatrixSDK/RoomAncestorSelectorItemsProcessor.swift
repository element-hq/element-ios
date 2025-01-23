//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class RoomAncestorSelectorItemsProcessor: MatrixItemChooserProcessorProtocol {
    // MARK: Private
    
    private let roomId: String
    
    // MARK: Setup
    
    init(roomId: String) {
        self.roomId = roomId
        dataSource = MatrixItemChooserRoomAncestorsDataSource(roomId: roomId)
    }
    
    // MARK: MatrixItemChooserSelectionProcessorProtocol
    
    private(set) var dataSource: MatrixItemChooserDataSource
    
    var loadingText: String? {
        nil
    }
    
    func computeSelection(withIds itemsIds: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        completion(Result.success(()))
    }
    
    func isItemIncluded(_ item: MatrixListItemData) -> Bool {
        true
    }
}
