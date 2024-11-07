//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class SpaceCreationAddRoomsItemsProcessor: MatrixItemChooserProcessorProtocol {
    // MARK: Private
    
    private let creationParams: SpaceCreationParameters
    
    // MARK: Setup
    
    init(creationParams: SpaceCreationParameters) {
        self.creationParams = creationParams
    }
    
    // MARK: MatrixItemChooserSelectionProcessorProtocol
    
    private(set) var dataSource: MatrixItemChooserDataSource = MatrixItemChooserRoomsDataSource()
    
    var loadingText: String? {
        nil
    }

    func computeSelection(withIds itemsIds: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        creationParams.addedRoomIds = itemsIds
        completion(.success(()))
    }
    
    func isItemIncluded(_ item: MatrixListItemData) -> Bool {
        true
    }
}
